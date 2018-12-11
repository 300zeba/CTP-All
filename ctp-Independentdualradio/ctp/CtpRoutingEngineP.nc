#include <Timer.h>
#include <TreeRouting.h>
#include <CollectionDebugMsg.h>
/* $Id: CtpRoutingEngineP.nc,v 1.25 2010-06-29 22:07:49 scipio Exp $ */
/*
 * Copyright (c) 2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the University of California nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

/** 
 *  The TreeRoutingEngine is responsible for computing the routes for
 *  collection.  It builds a set of trees rooted at specific nodes (roots) and
 *  maintains these trees using information provided by the link estimator on
 *  the quality of one hop links.
 * 
 *  <p>Each node is part of only one tree at any given time, but there is no
 *  difference from the node's point of view of which tree it is part. In other
 *  words, a message is sent towards <i>a</i> root, but which one is not
 *  specified. It is assumed that the roots will work together to have all data
 *  aggregated later if need be.  The tree routing engine's responsibility is
 *  for each node to find the path with the least number of transmissions to
 *  any one root.
 *
 *  <p>The tree is proactively maintained by periodic beacons sent by each
 *  node. These beacons are jittered in time to prevent synchronizations in the
 *  network. All nodes maintain the same <i>average</i> beacon sending1 rate
 *  (defined by BEACON_INTERVAL +- 50%). The beacon contains the node's parent,
 *  the current hopcount, and the cumulative path quality metric. The metric is
 *  defined as the parent's metric plus the bidirectional quality of the link
 *  between the current node and its parent.  The metric represents the
 *  expected number of transmissions along the path to the root, and is 0 by
 *  definition at the root.
 * 
 *  <p>Every time a node receives an update from a neighbor it records the
 *  information if the node is part of the neighbor table. The neighbor table
 *  keeps the best candidates for being parents i.e., the nodes with the best
 *  path metric. The neighbor table does not store the full path metric,
 *  though. It stores the parent's path metric, and the link quality to the
 *  parent is only added when the information is needed: (i) when choosing a
 *  parent and (ii) when choosing a route. The nodes in the neighbor table are
 *  a subset of the nodes in the link estimator table, as a node is not
 *  admitted in the neighbor table with an estimate of infinity.
 * 
 *  <p>There are two uses for the neighbor table, as mentioned above. The first
 *  one is to select a parent. The parent is just the neighbor with the best
 *  path metric. It serves to define the node's own path metric and hopcount,
 *  and the set of child-parent links is what defines the tree. In a sense the
 *  tree is defined to form a coherent propagation substrate for the path
 *  metrics. The parent is (re)-selected periodically, immediately before a
 *  node sends its own beacon, in the updateRouteTask.
 *  
 *  <p>The second use is to actually choose a next hop towards any root at
 *  message forwarding time.  This need not be the current parent, even though
 *  it is currently implemented as such.
 *
 *  <p>The operation of the routing engine has two main tasks and one main
 *  event: updateRouteTask is called periodically and chooses a new parent;
 *  sendBeaconTask broadcasts the current route information to the neighbors.
 *  The main event is the receiving of a neighbor's beacon, which updates the
 *  neighbor table.
 *  
 *  <p> The interface with the ForwardingEngine occurs through the nextHop()
 *  call.
 * 
 *  <p> Any node can become a root, and routed messages from a subset of the
 *  network will be routed towards it. The RootControl interface allows
 *  setting, unsetting, and querying the root state of a node. By convention,
 *  when a node is root its hopcount and metric are 0, and the parent is
 *  itself. A root always has a valid route, to itself.
 *
 *  @author Rodrigo Fonseca
 *  @author Philip Levis (added trickle-like updates)
 *  Acknowledgment: based on MintRoute, MultiHopLQI, BVR tree construction, Berkeley's MTree
 *                           
 *  @date   $Date: 2010-06-29 22:07:49 $
 *  @see Net2-WG
 */

generic module CtpRoutingEngineP(uint8_t routingTableSize, uint32_t minInterval, uint32_t maxInterval) {
    provides {
        interface UnicastNameFreeRoutingDual as Routing;
        interface RootControl;
        interface CtpInfo;
        interface StdControl;
        interface CtpRoutingPacket;
        interface Init;
    } 
    uses {
        interface AMSend as BeaconSend1;
        interface AMSend as BeaconSend2;
        interface Receive as BeaconReceive1;
        interface Receive as BeaconReceive2;
        interface LinkEstimator as LinkEstimator1;
        interface LinkEstimator as LinkEstimator2;
        interface AMPacket as AMPacket1;
        interface AMPacket as AMPacket2;
        interface SplitControl as RadiosControl;
        interface Timer<TMilli> as BeaconTimer;
        interface Timer<TMilli> as RouteTimer;
        interface Random;
        interface CollectionDebug;
        interface CtpCongestion;

	   interface CompareBit as CompareBit1;
       interface CompareBit as CompareBit2;

       interface SerialLogger;

    }
}


implementation {

    uint8_t radio = 1; //Which radio to use
    uint32_t beaconCount = 0;

    bool ECNOff = TRUE;

    /* Keeps track of whether the radio is on. No sense updating or sending1
     * beacons if radio is off */
    bool radioOn = FALSE;
    /* Controls whether the node's periodic timer will fire. The node will not
     * send any beacon, and will not update the route. Start and stop control this. */
    bool running = FALSE;
    /* Guards the beacon buffer: only one beacon being sent at a time */
    bool sending1 = FALSE;
    bool sending2 = FALSE;

    /* Tells updateNeighbor that the parent was just evicted.*/ 
    bool justEvicted1 = FALSE;
    bool justEvicted2 = FALSE;

    route_info_t routeInfo1;
    route_info_t routeInfo2;
    bool state_is_root;
    am_addr_t my_ll_addr;

    message_t beaconMsgBuffer1;
    message_t beaconMsgBuffer2;
    ctp_routing_header_t* beaconMsg;

    /* routing table -- routing info about neighbors */
    routing_table_entry routingTable1[routingTableSize];
    routing_table_entry routingTable2[routingTableSize];
    uint8_t routingTableActive1;
    uint8_t routingTableActive2;

    /* statistics */
    uint32_t parentChanges;
    /* end statistics */

    // forward declarations
    void routingTableInit();
    uint8_t routingTableFind(am_addr_t, uint8_t);
    error_t routingTableUpdateEntry(am_addr_t, am_addr_t , uint16_t, uint8_t);
    error_t routingTableEvict1(am_addr_t neighbor);
    error_t routingTableEvict2(am_addr_t neighbor);



  /* 
     For each interval t, you set a timer to fire between t/2 and t
     (chooseAdvertiseTime), and you wait until t (remainingInterval). Once
     you are at t, you double the interval (decayInterval) if you haven't
     reached the max. For reasons such as topological inconsistency, you
     reset the timer to a small value (resetInterval).
  */

    uint32_t currentInterval = minInterval;
    uint32_t t; 
    bool tHasPassed;


    void chooseAdvertiseTime() {
       t = currentInterval;
       t /= 2;
       t += call Random.rand32() % t;
       tHasPassed = FALSE;
       call BeaconTimer.startOneShot(t);
    }

    void resetInterval() {
      currentInterval = minInterval;
      chooseAdvertiseTime();
    }

    void decayInterval() {
        currentInterval *= 2;
        if (currentInterval > maxInterval) {
          currentInterval = maxInterval;
        }
      chooseAdvertiseTime();
    }

    void remainingInterval() {
       uint32_t remaining = currentInterval;
       remaining -= t;
       tHasPassed = TRUE;
       call BeaconTimer.startOneShot(remaining);
    }

    command error_t Init.init() {
        radioOn = FALSE;
        running = FALSE;
        parentChanges = 0;
        state_is_root = 0;
        routeInfoInit(&routeInfo1);
        routeInfoInit(&routeInfo2);
        routingTableInit();
        if(TOS_NODE_ID % 2 == 0){
            beaconMsg = call BeaconSend1.getPayload(&beaconMsgBuffer1, call BeaconSend1.maxPayloadLength());
            radio = 1;
        }
        else{
            beaconMsg = call BeaconSend2.getPayload(&beaconMsgBuffer2, call BeaconSend2.maxPayloadLength());
            radio = 2;
        }
        dbg("TreeRoutingCtl","TreeRouting initialized. (used payload:%d max payload:%d!\n", 
              sizeof(beaconMsg), call BeaconSend1.maxPayloadLength());
        return SUCCESS;
    }

    command error_t StdControl.start() {
      my_ll_addr = call AMPacket1.address();
      //start will (re)start the sending1 of messages
      if (!running) {
    	running = TRUE;
    	resetInterval();
    	call RouteTimer.startPeriodic(BEACON_INTERVAL);
    	dbg("TreeRoutingCtl","%s running: %d radioOn: %d\n", __FUNCTION__, running, radioOn);
      }     
      return SUCCESS;
    }

    command error_t StdControl.stop() {
        running = FALSE;
        dbg("TreeRoutingCtl","%s running: %d radioOn: %d\n", __FUNCTION__, running, radioOn);
        return SUCCESS;
    } 

    event void RadiosControl.startDone(error_t error) {
        radioOn = TRUE;
        dbg("TreeRoutingCtl","%s running: %d radioOn: %d\n", __FUNCTION__, running, radioOn);
        if (running) {
            uint16_t nextInt;
            nextInt = call Random.rand16() % BEACON_INTERVAL;
            nextInt += BEACON_INTERVAL >> 1;
        }
    } 

    event void RadiosControl.stopDone(error_t error) {
        radioOn = FALSE;
        dbg("TreeRoutingCtl","%s running: %d radioOn: %d\n", __FUNCTION__, running, radioOn);
    }

    /* Is this quality measure better than the minimum threshold? */
    // Implemented assuming quality is EETX
    bool passLinkEtxThreshold(uint16_t etx) {
        return (etx < ETX_THRESHOLD);
    }


    /* updates the routing information, using the info that has been received
     * from neighbor beacons. Two things can cause this info to change: 
     * neighbor beacons, changes in link estimates, including neighbor eviction */
    task void updateRouteTask() {
        uint8_t i;
        routing_table_entry* entry;
        routing_table_entry* best1;
        routing_table_entry* best2;
        uint16_t minEtx1;
        uint16_t minEtx2;
        uint16_t currentEtx1;
        uint16_t currentEtx2;
        uint16_t linkEtx, pathEtx;


        if (state_is_root)
            return;
       
        best1 = NULL;
        best2 = NULL;
        /* Minimum etx found among neighbors, initially infinity */
        minEtx1 = MAX_METRIC;
        minEtx2 = MAX_METRIC;
        /* Metric through current parent, initially infinity */
        currentEtx1 = MAX_METRIC;
        currentEtx2 = MAX_METRIC;

        dbg("TreeRouting","%s\n",__FUNCTION__);

        /* Find best path in table, other than our current */
        for (i = 0; i < routingTableActive1; i++) {
            entry = &routingTable1[i];

            // Avoid bad entries and 1-hop loops
            if (entry->info.parent == INVALID_ADDR || entry->info.parent == my_ll_addr) {
              dbg("TreeRouting", 
                  "routingTable1[%d]: neighbor: [id: %d parent: %d  etx: NO ROUTE]\n",  
                  i, entry->neighbor, entry->info.parent);
              continue;
            }

            linkEtx = call LinkEstimator1.getLinkQuality(entry->neighbor);
       
            pathEtx = linkEtx + entry->info.etx;
            /* Operations specific to the current parent */
            if (entry->neighbor == routeInfo1.parent) {
                dbg("TreeRouting", "   already parent.\n");
                currentEtx1 = pathEtx;
                /* update routeInfo1 with parent's current info */
		      routeInfo1.etx = entry->info.etx;
		      routeInfo1.congested = entry->info.congested;
                continue;
            }
            /* Ignore links that are congested */
            if (entry->info.congested)
                continue;
            /* Ignore links that are bad */
            if (!passLinkEtxThreshold(linkEtx)) {
              dbg("TreeRouting", "   did not pass threshold.\n");
              continue;
            }
            //call SerialLogger.log(LOG_ETX_1,pathEtx);
            
            if (pathEtx < minEtx1) {
	      dbg("TreeRouting", "   best is %d, setting to %d\n", pathEtx, entry->neighbor);
                minEtx1 = pathEtx;
                best1 = entry;
            }  
        }

        for (i = 0; i < routingTableActive2; i++) { //Using radio 2
            entry = &routingTable2[i];

            // Avoid bad entries and 1-hop loops
            if (entry->info.parent == INVALID_ADDR || entry->info.parent == my_ll_addr) {
              dbg("TreeRouting", 
                  "routingTable2[%d]: neighbor: [id: %d parent: %d  etx: NO ROUTE]\n",  
                  i, entry->neighbor, entry->info.parent);
              continue;
            }

            linkEtx = call LinkEstimator2.getLinkQuality(entry->neighbor);
            dbg("TreeRouting", 
                "routingTable2[%d]: neighbor: [id: %d parent: %d etx: %d retx: %d]\n",  
                i, entry->neighbor, entry->info.parent, linkEtx, entry->info.etx);
            pathEtx = linkEtx + entry->info.etx;
            /* Operations specific to the current parent */
            if (entry->neighbor == routeInfo2.parent) {
                dbg("TreeRouting", "   already parent.\n");
                currentEtx2 = pathEtx;
                /* update routeInfo with parent's current info */
                routeInfo2.etx = entry->info.etx;
                routeInfo2.congested = entry->info.congested;
                continue;
            }
            /* Ignore links that are congested */
            if (entry->info.congested)
                continue;
            /* Ignore links that are bad */
            if (!passLinkEtxThreshold(linkEtx)) {
              dbg("TreeRouting", "   did not pass threshold.\n");
              continue;
            }
            //call SerialLogger.log(LOG_ETX_2,pathEtx);
            
            if (pathEtx < minEtx2) {
          dbg("TreeRouting", "   best is %d, setting to %d\n", pathEtx, entry->neighbor);
                minEtx2 = pathEtx;
                best2 = entry;
            }  
        }
        call SerialLogger.log(LOG_MIN_ETX_1,minEtx1);
        call SerialLogger.log(LOG_MIN_ETX_2,minEtx2);

  

        /* Now choose between the current parent and the best neighbor */
        /* Requires that: 
            1. at least another neighbor was found with ok quality and not congested
            2. the current parent is congested and the other best route is at least as good
            3. or the current parent is not congested and the neighbor quality is better by 
               the PARENT_SWITCH_THRESHOLD.
          Note: if our parent is congested, in order to avoid forming loops, we try to select
                a node which is not a descendent of our parent. routeInfo.ext is our parent's
                etx. Any descendent will be at least that + 10 (1 hop), so we restrict the 
                selection to be less than that.
        */
        if (minEtx1 != MAX_METRIC) {
            if (currentEtx1 == MAX_METRIC ||
                (routeInfo1.congested && (minEtx1 < (routeInfo1.etx + 10))) ||
                minEtx1 + PARENT_SWITCH_THRESHOLD < currentEtx1) {
                // routeInfo.metric will not store the composed metric.
                // since the linkMetric may change, we will compose whenever
                // we need it: i. when choosing a parent (here); 
                //            ii. when choosing a next hop
                parentChanges++;

                dbg("TreeRouting","Changed parent. from %d to %d\n", routeInfo1.parent, best1->neighbor);
                call CollectionDebug.logEventDbg(NET_C_TREE_NEW_PARENT, best1->neighbor, best1->info.etx, minEtx1);
                call LinkEstimator1.unpinNeighbor(routeInfo1.parent);
                call LinkEstimator1.pinNeighbor(best1->neighbor);
                call LinkEstimator1.clearDLQ(best1->neighbor);

        routeInfo1.parent = best1->neighbor;
        routeInfo1.etx = best1->info.etx;
        routeInfo1.congested = best1->info.congested;
        if (currentEtx1 - minEtx1 > 20) {
          call CtpInfo.triggerRouteUpdate();
        }
            }
        }    

        /* Finally, tell people what happened:  */
        /* We can only loose a route to a parent if it has been evicted. If it hasn't 
         * been just evicted then we already did not have a route */
        if (justEvicted1 && routeInfo1.parent == INVALID_ADDR) 
            signal Routing.noRoute();
        /* On the other hand, if we didn't have a parent (no currentEtx1) and now we
         * do, then we signal route found. The exception is if we just evicted the 
         * parent and immediately found a replacement route: we don't signal in this 
         * case */
        else if (!justEvicted1 && 
                  currentEtx1 == MAX_METRIC &&
                  minEtx1 != MAX_METRIC)
            signal Routing.routeFound();
        justEvicted1 = FALSE;


        if (minEtx2 != MAX_METRIC) {
            if (currentEtx2 == MAX_METRIC ||
                (routeInfo2.congested && (minEtx2 < (routeInfo2.etx + 10))) ||
                minEtx2 + PARENT_SWITCH_THRESHOLD < currentEtx2) {
                // routeInfo.metric will not store the composed metric.
                // since the linkMetric may change, we will compose whenever
                // we need it: i. when choosing a parent (here); 
                //            ii. when choosing a next hop
                parentChanges++;

                dbg("TreeRouting","Changed parent. from %d to %d\n", routeInfo2.parent, best2->neighbor);
                call CollectionDebug.logEventDbg(NET_C_TREE_NEW_PARENT, best2->neighbor, best2->info.etx, minEtx2);
                call LinkEstimator2.unpinNeighbor(routeInfo2.parent);
                call LinkEstimator2.pinNeighbor(best2->neighbor);
                call LinkEstimator2.clearDLQ(best2->neighbor);

        routeInfo2.parent = best2->neighbor;
        routeInfo2.etx = best2->info.etx;
        routeInfo2.congested = best2->info.congested;
        if (currentEtx2 - minEtx2 > 20) {
          call CtpInfo.triggerRouteUpdate();
        }
            }
        }    

        /* Finally, tell people what happened:  */
        /* We can only loose a route to a parent if it has been evicted. If it hasn't 
         * been just evicted then we already did not have a route */
        if (justEvicted2 && routeInfo2.parent == INVALID_ADDR) 
            signal Routing.noRoute();
        /* On the other hand, if we didn't have a parent (no currentEtx2) and now we
         * do, then we signal route found. The exception is if we just evicted the 
         * parent and immediately found a replacement route: we don't signal in this 
         * case */
        else if (!justEvicted2 && 
                  currentEtx2 == MAX_METRIC &&
                  minEtx2 != MAX_METRIC)
            signal Routing.routeFound();
        justEvicted2 = FALSE;
    }

    

    /* send a beacon advertising this node's routeInfo1 */
    // only posted if running and radioOn
    task void sendBeaconTask() {
        error_t eval;
        if(radio == 1){
            radio = 2;
            if (sending1) {
                return;
            }
            call SerialLogger.log(LOG_CURRENT_DAD,routeInfo1.parent);
            call SerialLogger.log(LOG_SENDING_BEACON_RADIO,1);

            beaconMsg->options = 0;

            /* Congestion notification: am I congested? */
            if (call CtpCongestion.isCongested()) {
                beaconMsg->options |= CTP_OPT_ECN;
            }
            beaconMsg->parent = routeInfo1.parent;
            if (state_is_root) {
                //beaconMsg->etx = routeInfo1.etx;
                beaconMsg->etx = 0;
            }
            else if (routeInfo1.parent == INVALID_ADDR) {
                beaconMsg->etx = routeInfo1.etx;
                beaconMsg->options |= CTP_OPT_PULL;
            } else {

                beaconMsg->etx = routeInfo1.etx + call LinkEstimator1.getLinkQuality(routeInfo1.parent);
            }

                dbg("TreeRouting", "%s parent: %d etx: %d\n",
                          __FUNCTION__,
                          beaconMsg->parent, 
                          beaconMsg->etx);
                call CollectionDebug.logEventRoute(NET_C_TREE_SENT_BEACON, beaconMsg->parent, 0, beaconMsg->etx);
                    
                eval = call BeaconSend1.send(AM_BROADCAST_ADDR, 
                                                &beaconMsgBuffer1, 
                                                sizeof(ctp_routing_header_t));
               


                if (eval == SUCCESS) {
                    beaconCount++;
                    call SerialLogger.log(LOG_SENT_BEACON,radio);
                    sending1 = TRUE;
                } else if (eval == EOFF) {
                    radioOn = FALSE;
                    dbg("TreeRoutingCtl","%s running: %d radioOn: %d\n", __FUNCTION__, running, radioOn);
                }

        }
        else{
             radio = 1;
            if (sending2) {
                return;
            }
            call SerialLogger.log(LOG_CURRENT_DAD,routeInfo2.parent);
            call SerialLogger.log(LOG_SENDING_BEACON_RADIO,2);

            beaconMsg->options = 0;

            /* Congestion notification: am I congested? */
            if (call CtpCongestion.isCongested()) {
                beaconMsg->options |= CTP_OPT_ECN;
            }
            beaconMsg->parent = routeInfo2.parent;
            if (state_is_root) {
                //beaconMsg->etx = routeInfo2.etx;
                beaconMsg->etx = 0;
            }
            else if (routeInfo2.parent == INVALID_ADDR) {
                beaconMsg->etx = routeInfo2.etx;
                beaconMsg->options |= CTP_OPT_PULL;
            } else {

                beaconMsg->etx = routeInfo2.etx + call LinkEstimator2.getLinkQuality(routeInfo2.parent);
            }

                dbg("TreeRouting", "%s parent: %d etx: %d\n",
                          __FUNCTION__,
                          beaconMsg->parent, 
                          beaconMsg->etx);
                call CollectionDebug.logEventRoute(NET_C_TREE_SENT_BEACON, beaconMsg->parent, 0, beaconMsg->etx);
                    
                eval = call BeaconSend2.send(AM_BROADCAST_ADDR, 
                                                &beaconMsgBuffer2, 
                                                sizeof(ctp_routing_header_t));
                


                if (eval == SUCCESS) {
                    beaconCount++;
                    call SerialLogger.log(LOG_SENT_BEACON,radio);
                    sending2 = TRUE;
                } else if (eval == EOFF) {
                    radioOn = FALSE;
                    dbg("TreeRoutingCtl","%s running: %d radioOn: %d\n", __FUNCTION__, running, radioOn);
                }

            
        }
    }

    event void BeaconSend1.sendDone(message_t* msg, error_t error) {
        if ((msg != &beaconMsgBuffer1) || !sending1) {
            //something smells bad around here
            return;
        }
        sending1 = FALSE;
    }

    event void BeaconSend2.sendDone(message_t* msg, error_t error) {
        if ((msg != &beaconMsgBuffer2) || !sending2) {
            //something smells bad around here
            return;
        }
        sending2 = FALSE;
    }

    event void RouteTimer.fired() {
      if (radioOn && running) {
         post updateRouteTask();
      }
    }
      
    event void BeaconTimer.fired() {
      if (radioOn && running) {
        if (!tHasPassed) {
          post updateRouteTask(); //always send the most up to date info
          post sendBeaconTask();
          dbg("RoutingTimer", "Beacon timer fired at %s\n", sim_time_string());
          remainingInterval();
        }
        else {
          decayInterval();
        }
      }
    }


    ctp_routing_header_t* getHeader(message_t* ONE m) {
      return (ctp_routing_header_t*)call BeaconSend1.getPayload(m, call BeaconSend1.maxPayloadLength());
    }
    
    
    /* Handle the receiving of beacon messages from the neighbors. We update the
     * table, but wait for the next route update to choose a new parent */
    event message_t* BeaconReceive1.receive(message_t* msg, void* payload, uint8_t len) {
        am_addr_t from;
        ctp_routing_header_t* rcvBeacon;
        bool congested;

        // Received a beacon, but it's not from us.
        if (len != sizeof(ctp_routing_header_t)) {
          dbg("LITest", "%s, received beacon of size %hhu, expected %i\n",
                     __FUNCTION__, 
                     len,
                     (int)sizeof(ctp_routing_header_t));
              
          return msg;
        }
       
        //need to get the am_addr_t of the source
        from = call AMPacket1.source(msg);
        rcvBeacon = (ctp_routing_header_t*)payload;

        //call SerialLogger.log(LOG_RECEIVED_BEACON,1);
        //call SerialLogger.log(LOG_FROM,from);

        congested = call CtpRoutingPacket.getOption(msg, CTP_OPT_ECN);

        dbg("TreeRouting","%s from: %d  [ parent: %d etx: %d]\n",
            __FUNCTION__, from, 
            rcvBeacon->parent, rcvBeacon->etx);

        //update neighbor table
        if (rcvBeacon->parent != INVALID_ADDR) {

            /* If this node is a root, request a forced insert in the link
             * estimator table and pin the node. */
            if (rcvBeacon->etx == 0) {
                dbg("TreeRouting","from a root, inserting if not in table\n");
                call LinkEstimator1.insertNeighbor(from);
                call LinkEstimator1.pinNeighbor(from);
            }
            //TODO: also, if better than my current parent's path etx, insert

            routingTableUpdateEntry(from, rcvBeacon->parent, rcvBeacon->etx,1);
            call CtpInfo.setNeighborCongested(from, congested,1);
        }

        if (call CtpRoutingPacket.getOption(msg, CTP_OPT_PULL)) {
              resetInterval();
        }
        return msg;
    }

    event message_t* BeaconReceive2.receive(message_t* msg, void* payload, uint8_t len) {
        am_addr_t from;
        ctp_routing_header_t* rcvBeacon;
        bool congested;

        // Received a beacon, but it's not from us.
        if (len != sizeof(ctp_routing_header_t)) {
          dbg("LITest", "%s, received beacon of size %hhu, expected %i\n",
                     __FUNCTION__, 
                     len,
                     (int)sizeof(ctp_routing_header_t));
              
          return msg;
        }
       // call SerialLogger.log(LOG_RECEIVED_BEACON,2);
        //need to get the am_addr_t of the source
        from = call AMPacket2.source(msg);
        rcvBeacon = (ctp_routing_header_t*)payload;
        //call SerialLogger.log(LOG_FROM,from);

        congested = call CtpRoutingPacket.getOption(msg, CTP_OPT_ECN);

        dbg("TreeRouting","%s from: %d  [ parent: %d etx: %d]\n",
            __FUNCTION__, from, 
            rcvBeacon->parent, rcvBeacon->etx);

        //update neighbor table
        if (rcvBeacon->parent != INVALID_ADDR) {

            /* If this node is a root, request a forced insert in the link
             * estimator table and pin the node. */
            if (rcvBeacon->etx == 0) {
                dbg("TreeRouting","from a root, inserting if not in table\n");
                call LinkEstimator2.insertNeighbor(from);
                call LinkEstimator2.pinNeighbor(from);
            }
            //TODO: also, if better than my current parent's path etx, insert

            routingTableUpdateEntry(from, rcvBeacon->parent, rcvBeacon->etx,2);
            call CtpInfo.setNeighborCongested(from, congested,2);
        }

        if (call CtpRoutingPacket.getOption(msg, CTP_OPT_PULL)) {
              resetInterval();
        }
        return msg;
    }


    /* Signals that a neighbor is no longer reachable. need special care if
     * that neighbor is our parent */
    event void LinkEstimator1.evicted(am_addr_t neighbor) {
        routingTableEvict1(neighbor);
        dbg("TreeRouting","%s\n",__FUNCTION__);
        if (routeInfo1.parent == neighbor) {
            routeInfoInit(&routeInfo1);
            justEvicted1 = TRUE;
            post updateRouteTask();
        }
    }

    event void LinkEstimator2.evicted(am_addr_t neighbor) {
        routingTableEvict2(neighbor);
        dbg("TreeRouting","%s\n",__FUNCTION__);
        if (routeInfo1.parent == neighbor) {
            routeInfoInit(&routeInfo2 );
            justEvicted2 = TRUE;
            post updateRouteTask();
        }
    }


    /* Interface UnicastNameFreeRouting */
    /* Simple implementation: return the current routeInfo1 */
    command am_addr_t Routing.nextHop1() {
        return routeInfo1.parent;    
    }
    command am_addr_t Routing.nextHop2() {
        return routeInfo2.parent;    
    }
    command bool Routing.hasRoute1() {
        return (routeInfo1.parent != INVALID_ADDR);
    }
    command bool Routing.hasRoute2() {
        return (routeInfo2.parent != INVALID_ADDR);
    }
   
    /* CtpInfo interface */
    command error_t CtpInfo.getParent1(am_addr_t* parent) {
        if (parent == NULL) 
            return FAIL;
        if (routeInfo1.parent == INVALID_ADDR)    
            return FAIL;
        *parent = routeInfo1.parent;
        return SUCCESS;
    }
    command error_t CtpInfo.getParent2(am_addr_t* parent) {
        if (parent == NULL) 
            return FAIL;
        if (routeInfo2.parent == INVALID_ADDR)    
            return FAIL;
        *parent = routeInfo2.parent;
        return SUCCESS;
    }


    command error_t CtpInfo.getEtx1(uint16_t* etx) {
        if (etx == NULL) 
            return FAIL;
        if (routeInfo1.parent == INVALID_ADDR)    
            return FAIL;
    	if (state_is_root == 1) {
    	  *etx = 0;
    	} else {
    	   *etx = routeInfo1.etx + call LinkEstimator1.getLinkQuality(routeInfo1.parent);
    	}
            return SUCCESS;
    }
    command error_t CtpInfo.getEtx2(uint16_t* etx) {
        if (etx == NULL) 
            return FAIL;
        if (routeInfo1.parent == INVALID_ADDR)    
            return FAIL;
        if (state_is_root == 1) {
          *etx = 0;
        } else {
           *etx = routeInfo2.etx + call LinkEstimator2.getLinkQuality(routeInfo2.parent);
        }
            return SUCCESS;
    }

    command void CtpInfo.recomputeRoutes() {
      post updateRouteTask();
    }

    command void CtpInfo.triggerRouteUpdate() {
      resetInterval();
     }

    command void CtpInfo.triggerImmediateRouteUpdate() {
      resetInterval();
    }

    command void CtpInfo.setNeighborCongested(am_addr_t n, bool congested, uint8_t table) {
        uint8_t idx;    
        if (ECNOff)
            return;
        idx = routingTableFind(n,table);
        if(table == 1){
            if (idx < routingTableActive1) {
                routingTable1[idx].info.congested = congested;
            }
            if (routeInfo1.congested && !congested) 
            post updateRouteTask();
        else if (routeInfo1.parent == n && congested) 
            post updateRouteTask();
    
        }
        else{
            if (idx < routingTableActive2) {
                routingTable2[idx].info.congested = congested;
            }
            if (routeInfo2.congested && !congested) 
            post updateRouteTask();
        else if (routeInfo2.parent == n && congested) 
            post updateRouteTask();
        }

    }

    command bool CtpInfo.isNeighborCongested(am_addr_t n) {
        uint8_t idx;    

        if (ECNOff) 
            return FALSE;

        idx = routingTableFind(n,1);

        if (idx < routingTableActive1) {
            if(routingTable1[idx].info.congested){
                idx = routingTableFind(n,2);

                if (idx < routingTableActive2) {
                    return routingTable2[idx].info.congested;
                }

            }
        }
       
        return FALSE;
    }
    
    /*
    command uint8_t CtpInfo.current_radio(){
        return radio;
    }*/
    
    /* RootControl interface */
    /** sets the current node as a root, if not already a root */
    /*  returns FAIL if it's not possible for some reason      */
    command error_t RootControl.setRoot() {
        bool route_found = FALSE;
        route_found = (routeInfo1.parent == INVALID_ADDR && routeInfo2.parent == INVALID_ADDR);
	state_is_root = 1;

	routeInfo1.parent = my_ll_addr; //myself
	routeInfo1.etx = 0;
    routeInfo2.parent = my_ll_addr; //myself
    routeInfo2.etx = 0;

        if (route_found) 
            signal Routing.routeFound();
        dbg("TreeRouting","%s I'm a root now!\n",__FUNCTION__);
        call CollectionDebug.logEventRoute(NET_C_TREE_NEW_PARENT, routeInfo1.parent, 0, routeInfo1.etx);
        return SUCCESS;
    }

    command error_t RootControl.unsetRoot() {
      state_is_root = 0;
      routeInfoInit(&routeInfo1);
      routeInfoInit(&routeInfo2);

      dbg("TreeRouting","%s I'm not a root now!\n",__FUNCTION__);
      post updateRouteTask();
      return SUCCESS;
    }

    command bool RootControl.isRoot() {
        return state_is_root;
    }

    default event void Routing.noRoute() {
    }
    
    default event void Routing.routeFound() {
    }


  /* The link will be recommended for insertion if it is better* than some
   * link in the routing table that is not our parent.
   * We are comparing the path quality up to the node, and ignoring the link
   * quality from us to the node. This is because of a couple of things:
   *   1. we expect this call only for links with white bit set
   *   2. we are being optimistic to the nodes in the table, by ignoring the
   *      1-hop quality to them (which means we are assuming it's 1 as well)
   *      This actually sets the bar a little higher for replacement
   *   3. this is faster
   */
    event bool CompareBit1.shouldInsert(message_t *msg, void* payload, uint8_t len) {
        
        bool found = FALSE;
        uint16_t pathEtx;
        uint16_t neighEtx;
        int i;
        routing_table_entry* entry;
        ctp_routing_header_t* rcvBeacon;

        if ((call AMPacket1.type(msg) != AM_CTP_ROUTING) ||
            (len != sizeof(ctp_routing_header_t))) 
            return FALSE;

        /* 1.determine this packet's path quality */
        rcvBeacon = (ctp_routing_header_t*)payload;

        if (rcvBeacon->parent == INVALID_ADDR)
            return FALSE;
        /* the node is a root, recommend insertion! */
        if (rcvBeacon->etx == 0) {
            return TRUE;
        }
    
        pathEtx = rcvBeacon->etx; // + linkEtx;

        /* 2. see if we find some neighbor that is worse */
        for (i = 0; i < routingTableActive1 && !found; i++) {
            entry = &routingTable1[i];
            //ignore parent, since we can't replace it
            if (entry->neighbor == routeInfo1.parent)
                continue;
            neighEtx = entry->info.etx;
            found |= (pathEtx < neighEtx); 
        }
        return found;
    }

    event bool CompareBit2.shouldInsert(message_t *msg, void* payload, uint8_t len) {
        
        bool found = FALSE;
        uint16_t pathEtx;
        uint16_t neighEtx;
        int i;
        routing_table_entry* entry;
        ctp_routing_header_t* rcvBeacon;

        if ((call AMPacket2.type(msg) != AM_CTP_ROUTING) ||
            (len != sizeof(ctp_routing_header_t))) 
            return FALSE;

        /* 1.determine this packet's path quality */
        rcvBeacon = (ctp_routing_header_t*)payload;

        if (rcvBeacon->parent == INVALID_ADDR)
            return FALSE;
        /* the node is a root, recommend insertion! */
        if (rcvBeacon->etx == 0) {
            return TRUE;
        }
    
        pathEtx = rcvBeacon->etx; // + linkEtx;

        /* 2. see if we find some neighbor that is worse */
        for (i = 0; i < routingTableActive2 && !found; i++) {
            entry = &routingTable2[i];
            //ignore parent, since we can't replace it
            if (entry->neighbor == routeInfo1.parent)
                continue;
            neighEtx = entry->info.etx;
            found |= (pathEtx < neighEtx); 
        }
        return found;
    }



    /************************************************************/
    /* Routing Table Functions                                  */

    /* The routing table keeps info about neighbor's route_info,
     * and is used when choosing a parent.
     * The table is simple: 
     *   - not fragmented (all entries in 0..routingTableActive1)
     *   - not ordered
     *   - no replacement: eviction follows the LinkEstimator1 table
     */

    void routingTableInit() {
        routingTableActive1 = 0;
        routingTableActive2 = 0;
    }

    /* Returns the index of parent in the table or
     * routingTableActive1 if not found */
    uint8_t routingTableFind(am_addr_t neighbor, uint8_t table) {
        if(table == 1){
            uint8_t i;
            if (neighbor == INVALID_ADDR)
                return routingTableActive1;
            for (i = 0; i < routingTableActive1; i++) {
                if (routingTable1[i].neighbor == neighbor)
                    break;
            }
            return i;
        }
        else{
            uint8_t i;
            if (neighbor == INVALID_ADDR)
                return routingTableActive2;
            for (i = 0; i < routingTableActive2; i++) {
                if (routingTable2[i].neighbor == neighbor)
                    break;
            }
            return i;
        }
    }


    error_t routingTableUpdateEntry(am_addr_t from, am_addr_t parent, uint16_t etx, uint8_t table)    {
        uint8_t idx;
        uint16_t  linkEtx;

        if(table == 1){ 
            linkEtx = call LinkEstimator1.getLinkQuality(from);

            idx = routingTableFind(from,table);
            if (idx == routingTableSize) {
                //not found and table is full
                //if (passLinkEtxThreshold(linkEtx))
                    //TODO: add replacement here, replace the worst
                //}
                dbg("TreeRouting", "%s FAIL, table full\n", __FUNCTION__);
                return FAIL;
            }
            else if (idx == routingTableActive1) {
                //not found and there is space
                if (passLinkEtxThreshold(linkEtx)) {
    	      routingTable1[idx].neighbor = from;
    	      routingTable1[idx].info.parent = parent;
    	      routingTable1[idx].info.etx = etx;
    	      routingTable1[idx].info.haveHeard = 1;
    	      routingTable1[idx].info.congested = FALSE;
    	      routingTableActive1++;
    	      dbg("TreeRouting", "%s OK, new entry\n", __FUNCTION__);
                } else {
                    dbg("TreeRouting", "%s Fail, link quality (%hu) below threshold\n", __FUNCTION__, linkEtx);
                }
            } else {
                //found, just update
        	  routingTable1[idx].neighbor = from;
        	  routingTable1[idx].info.parent = parent;
        	  routingTable1[idx].info.etx = etx;
        	  routingTable1[idx].info.haveHeard = 1;
        	  dbg("TreeRouting", "%s OK, updated entry\n", __FUNCTION__);
            }
        }
        else{ 
            linkEtx = call LinkEstimator2.getLinkQuality(from);

            idx = routingTableFind(from,table);
            if (idx == routingTableSize) {
                //not found and table is full
                //if (passLinkEtxThreshold(linkEtx))
                    //TODO: add replacement here, replace the worst
                //}
                dbg("TreeRouting", "%s FAIL, table full\n", __FUNCTION__);
                return FAIL;
            }
            else if (idx == routingTableActive2) {
                //not found and there is space
                if (passLinkEtxThreshold(linkEtx)) {
              routingTable2[idx].neighbor = from;
              routingTable2[idx].info.parent = parent;
              routingTable2[idx].info.etx = etx;
              routingTable2[idx].info.haveHeard = 1;
              routingTable2[idx].info.congested = FALSE;
              routingTableActive2++;
              dbg("TreeRouting", "%s OK, new entry\n", __FUNCTION__);
                } else {
                    dbg("TreeRouting", "%s Fail, link quality (%hu) below threshold\n", __FUNCTION__, linkEtx);
                }
            } else {
                //found, just update
              routingTable2[idx].neighbor = from;
              routingTable2[idx].info.parent = parent;
              routingTable2[idx].info.etx = etx;
              routingTable2[idx].info.haveHeard = 1;
              dbg("TreeRouting", "%s OK, updated entry\n", __FUNCTION__);
            }
        }
        return SUCCESS;
    }

    /* if this gets expensive, introduce indirection through an array of pointers */
    error_t routingTableEvict1(am_addr_t neighbor) {
        uint8_t idx,i;
        idx = routingTableFind(neighbor,1);
        if (idx == routingTableActive1) 
            return FAIL;
        routingTableActive1--;
        for (i = idx; i < routingTableActive1; i++) {
            routingTable1[i] = routingTable1[i+1];    
        } 
        return SUCCESS; 
    }

    error_t routingTableEvict2(am_addr_t neighbor) {
        uint8_t idx,i;
        idx = routingTableFind(neighbor,2);
        if (idx == routingTableActive2) 
            return FAIL;
        routingTableActive2--;
        for (i = idx; i < routingTableActive2; i++) {
            routingTable2[i] = routingTable2[i+1];    
        } 
        return SUCCESS; 
    }
    /*********** end routing table functions ***************/

    /* Default implementations for CollectionDebug calls.
     * These allow CollectionDebug not to be wired to anything if debugging
     * is not desired. */

    default command error_t CollectionDebug.logEvent(uint8_t type) {
        return SUCCESS;
    }
    default command error_t CollectionDebug.logEventSimple(uint8_t type, uint16_t arg) {
        return SUCCESS;
    }
    default command error_t CollectionDebug.logEventDbg(uint8_t type, uint16_t arg1, uint16_t arg2, uint16_t arg3) {
        return SUCCESS;
    }
    default command error_t CollectionDebug.logEventMsg(uint8_t type, uint16_t msg, am_addr_t origin, am_addr_t node) {
        return SUCCESS;
    }
    default command error_t CollectionDebug.logEventRoute(uint8_t type, am_addr_t parent, uint8_t hopcount, uint16_t etx) {
        return SUCCESS;
    }

    command bool CtpRoutingPacket.getOption(message_t* msg, ctp_options_t opt) {
      return ((getHeader(msg)->options & opt) == opt) ? TRUE : FALSE;
    }

    command void CtpRoutingPacket.setOption(message_t* msg, ctp_options_t opt) {
      getHeader(msg)->options |= opt;
    }

    command void CtpRoutingPacket.clearOption(message_t* msg, ctp_options_t opt) {
      getHeader(msg)->options &= ~opt;
    }

    command void CtpRoutingPacket.clearOptions(message_t* msg) {
      getHeader(msg)->options = 0;
    }

    
    command am_addr_t     CtpRoutingPacket.getParent(message_t* msg) {
      return getHeader(msg)->parent;
    }
    command void          CtpRoutingPacket.setParent(message_t* msg, am_addr_t addr) {
      getHeader(msg)->parent = addr;
    }
    
    command uint16_t      CtpRoutingPacket.getEtx(message_t* msg) {
      return getHeader(msg)->etx;
    }
    command void          CtpRoutingPacket.setEtx(message_t* msg, uint16_t etx) {
      getHeader(msg)->etx = etx;
    }

    command uint8_t CtpInfo.numNeighbors() {
      return routingTableActive1;
    }
    command uint16_t CtpInfo.getNeighborLinkQuality(uint8_t n) {
      return (n < routingTableActive1)? call LinkEstimator1.getLinkQuality(routingTable1[n].neighbor):0xffff;
    }
    command uint16_t CtpInfo.getNeighborRouteQuality(uint8_t n) {
      return (n < routingTableActive1)? call LinkEstimator1.getLinkQuality(routingTable1[n].neighbor) + routingTable1[n].info.etx:0xfffff;
    }
    command am_addr_t CtpInfo.getNeighborAddr(uint8_t n) {
      return (n < routingTableActive1)? routingTable1[n].neighbor:AM_BROADCAST_ADDR;
    }
    command uint32_t CtpInfo.totalBeacons() {
      return beaconCount;
    }
    
} 
