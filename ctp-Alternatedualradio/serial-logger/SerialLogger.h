#ifndef SERIAL_LOGGER_H
#define SERIAL_LOGGER_H

#define SERIAL_TIMER_PERIOD_MILLI 250

/*enum {
  LOG_NUM_PATHS,
  LOG_ROOT_ACTION,
  LOG_RESEND_PATHS,
  LOG_RECEIVED_COUNT,
  LOG_SEND_COUNT,
  LOG_TOTAL_SENT,
  LOG_ERROR_MPDR_SEND,
  LOG_MPDR_SEND_DONE,
  LOG_ERROR_MPDR_SEND_DONE,
  LOG_MPDR_RECEIVE,
  LOG_MPDR_PATHS_READY,
  LOG_RECEIVED_RADIO_1_SOURCE,
  LOG_RECEIVED_RADIO_2_SOURCE,
  LOG_MESSAGE_SIZE,
  LOG_THROUGHPUT,
  LOG_ROUTING_ERROR,
  LOG_START_SENDING,
  LOG_STOP_SENDING,
  LOG_SET_RADIO_1_CHANNEL,
  LOG_SET_RADIO_2_CHANNEL,
  LOG_SET_RADIO_1_CHANNEL_OK,
  LOG_SET_RADIO_2_CHANNEL_OK,
  LOG_RCV_ROUTING_LAST_HOP,
  LOG_RCV_ROUTING_LAST_RADIO,
  LOG_RCV_ROUTING_LAST_CHANNEL,
  LOG_SEND_1_ERROR,
  LOG_SEND_2_ERROR,
  LOG_RECEIVED_RADIO_1_LAST_HOP,
  LOG_RECEIVED_RADIO_2_LAST_HOP,
  LOG_RADIO_1_SEND_RESULT,
  LOG_RADIO_2_SEND_RESULT,
  LOG_RADIO_1_SEND_RESULT_2,
  LOG_RADIO_2_SEND_RESULT_2,
  LOG_RADIO_1_ENQUEUE_RESULT,
  LOG_RADIO_2_ENQUEUE_RESULT,
  LOG_RECEIVED_RADIO_1_SEQNO,
  LOG_RECEIVED_RADIO_2_SEQNO,
  LOG_GET_NEXT_HOP,
  LOG_SET_RADIO_1_CHANNEL_ERROR,
  LOG_SET_RADIO_2_CHANNEL_ERROR,
  LOG_DROP_COUNT,
  LOG_RADIO_NUMBER_ERROR,
  LOG_CHANNEL_NUMBER_ERROR,
  LOG_CHANGE_CHANNEL_ATTEMPTS,
  LOG_GET_RELAY_CHANNEL_ERROR,
  LOG_SENDING_RADIO_1_TO,
  LOG_SENDING_RADIO_2_TO,
  LOG_ENQUEUEING_RADIO_1,
  LOG_ENQUEUEING_RADIO_2,
  LOG_MSG_ERROR_I,
  LOG_MSG_ERROR_DATA,
  LOG_RECEIVED_RADIO_1_DESTINATION,
  LOG_RECEIVED_RADIO_1_NEXT_HOP,
  LOG_RECEIVED_RADIO_2_DESTINATION,
  LOG_RECEIVED_RADIO_2_NEXT_HOP,
  LOG_TOS_NODE_ID,
  LOG_REQUEST_ACK_1_ERROR,
  LOG_REQUEST_ACK_2_ERROR,
  LOG_SEND_DONE_1_ERROR,
  LOG_SEND_DONE_2_ERROR,
  LOG_INITIALIZED,
  LOG_DESTINATION_NODE,
  LOG_SOURCE_NODE,
  LOG_RELAY_NODE,
  LOG_ELAPSED_TIME,
  LOG_PAYLOAD_SIZE,
};*/

typedef nx_struct serial_log_message {
  nx_uint16_t evt;
  nx_uint16_t data;
} serial_log_message_t;

#endif
