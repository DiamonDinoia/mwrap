# See www.zlib.net
include ../../make.inc
MW=../../mwrap

gzmex:
	$(MW) -mex gzmex -mb gzfile.mw
	$(MW) -mex gzmex -c gzmex.cc gzfile.mw
	$(MEX) gzmex.cc -lz

clean:
	rm -f gz*.m gzmex.* *.o* eye.gz
