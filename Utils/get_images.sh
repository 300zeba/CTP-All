cd /home/twonet/Desktop/ctp-Alternatedualradio/TestCtp/
make opal
mv /home/twonet/Desktop/ctp-Alternatedualradio/TestCtp/build/opal/main.exe /home/twonet/Desktop/images-temp/CtpAltDelay$1.exe

cd /home/twonet/Desktop/ctp-singleradio/TestCtp/
make opal
cd
mv /home/twonet/Desktop/ctp-singleradio/TestCtp/build/opal/main.exe /home/twonet/Desktop/images-temp/CtpSingleDelay$1.exe

cd /home/twonet/Desktop/ctp-independentDualRadio/TestCtp/
make opal
cd
mv /home/twonet/Desktop/ctp-independentDualRadio/TestCtp/build/opal/main.exe /home/twonet/Desktop/images-temp/CtpIndDelay$1.exe

cd /home/twonet/Desktop/ctp-Comparison/TestCtp/
make opal
cd
mv /home/twonet/Desktop/ctp-Comparison/TestCtp/build/opal/main.exe /home/twonet/Desktop/images-temp/CtpCompDelay$1.exe
