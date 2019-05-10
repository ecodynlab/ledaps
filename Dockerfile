FROM scratch
MAINTAINER Aditya Singh <aditya01@ufl.edu>

USER root
RUN apt-get update -y && \
	apt-get install -y \
	zlib1g zlib1g-dev libtiff5 libtiff5-dev \
	libgeotiff2 libgeotiff-dev libhdf4-dev libhdf5-dev libxml2 libxml2-dev \
	g++ gfortran bison byacc flex csh make \
	nano subversion git curl

ENV USERNAME=root
RUN mkdir /usr/local/hdf4 && sudo chown $USERNAME /usr/local/hdf4 && cd /usr/local/hdf4
RUN cd /usr/local/hdf4 && curl http://www.hdfgroup.org/ftp/HDF/HDF_Current/src/hdf-4.2.13.tar.gz -O -L && tar -xzvf hdf-4.2.13.tar.gz
RUN cd /usr/local/hdf4/hdf-4.2.13 && ./configure && make && make check && make install && ldconfig

RUN mkdir /usr/local/hdf5 && sudo chown $USERNAME /usr/local/hdf5 && cd /usr/local/hdf5
RUN cd /usr/local/hdf5 && curl https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.10/hdf5-1.10.5/src/hdf5-1.10.5.tar.gz -O -L && tar -xzvf hdf5-1.10.5.tar.gz
RUN cd /usr/local/hdf5/hdf5-1.10.5 && ./configure && make && make check && make install && ldconfig

RUN mkdir /usr/local/hdf-eos
RUN chown $USERNAME /usr/local/hdf-eos
RUN cd /usr/local/hdf-eos && curl -k https://observer.gsfc.nasa.gov/ftp/edhs/hdfeos/latest_release/HDF-EOS2.20v1.00.tar.Z -O && tar -xzvf HDF-EOS2.20v1.00.tar.Z
RUN cd /usr/local/hdf-eos/hdfeos && ./configure -enable-install-include CC=/usr/local/hdf4/hdf-4.2.13/hdf4/bin/h4cc && make && make check && make install && ldconfig

ENV HDFEOS_GCTPINC="/usr/include/gctp/"
ENV HDFEOS_GCTPLIB="/usr/local/hdf-eos/hdfeos/hdfeos2/lib"
ENV TIFFINC="/usr/include/x86_64-linux-gnu/"
ENV TIFFLIB="/usr/lib/x86_64-linux-gnu/"
ENV GEOTIFF_INC="/usr/include/geotiff/"
ENV GEOTIFF_LIB="/usr/lib/"
ENV HDFINC="/usr/local/hdf4/hdf-4.2.11/hdf4/include/"
ENV HDFLIB="/usr/local/hdf4/hdf-4.2.11/hdf4/lib/"
ENV HD5INC="/usr/local/hdf5/hdf5-1.10.5/hdf5/include/"
ENV HD5LIB="/usr/local/hdf5/hdf5-1.10.5/hdf5/lib/"
ENV HDFEOS_INC="/usr/local/hdf-eos/hdfeos/include/" # Where to find HE2_config.h
ENV HDFEOS_LIB="/usr/local/hdf-eos/hdfeos/hdfeos2/lib"
ENV JPEGINC="/usr/include/"
ENV JPEGLIB="/usr/lib/x86_64-linux-gnu/"
ENV XML2INC="/usr/include/libxml2/"
ENV XML2LIB="/usr/lib/x86_64-linux-gnu/"
ENV ZLIBINC="/usr/include/"
ENV ZLIBLIB="/usr/lib/x86_64-linux-gnu/"
ENV JBIGINC="/usr/include/"
ENV JBIGLIB="/usr/lib/x86_64-linux-gnu/"

# GET ESPA-FORMATTER
RUN cd /usr/local/ && git clone https://github.com/USGS-EROS/espa-product-formatter.git espa-common
RUN mkdir -p /usr/local/espa-tools
ENV PREFIX="/usr/local/espa-tools/"

# GET POLYGON
RUN cd /usr/local/espa-tools && mkdir static_data && cd static_data && curl -L http://edclpdsftp.cr.usgs.gov/downloads/auxiliaries/land_water_poly/land_no_buf.ply.gz -O && gunzip land_no_buf.ply.gz
ENV ESPA_LAND_MASS_POLYGON="$PREFIX/static_data/land_no_buf.ply"

# INSTALL ESPA LIBRARIES
RUN cd /usr/local/
RUN chown -R $USERNAME espa-common
RUN cd /usr/local/espa-common/raw_binary/ && make && make install && ldconfig

# These are the include and lib directories just created
ENV ESPAINC="/usr/local/espa-common/raw_binary/include/"
ENV ESPALIB="/usr/local/espa-common/raw_binary/lib/"

#GET AUXILIARY DATA
RUN cd /usr/local && mkdir ledaps-aux 
RUN cd /usr/local/ledaps-aux && curl -L http://edclpdsftp.cr.usgs.gov/downloads/auxiliaries/ledaps_auxiliary/ledaps_aux.1978-2017.tar.gz  -O && gunzip ledaps_aux.1978-2017.tar.gz
ENV LEDAPS_AUX_DIR="/usr/local/ledaps-aux/"

#GET SURFACE EFLECTANCE CODE AND INSTALL
RUN cd /usr/local && mkdir espa-surface && git clone https://github.com/USGS-EROS/espa-surface-reflectance.git  espa-surface/
ADD Makefile /usr/local/espa-surface/ledaps/ledapsSrc/src/lndsr/
RUN cd /usr/local/espa-surface/ledaps/ledapsSrc/src && make && make install
ENV BIN="/usr/local/espa-tools/bin"
RUN cp /usr/local/espa-surface/ledaps/ledapsSrc/scripts/do_ledaps.csh $BIN
RUN cp /usr/local/espa-surface/ledaps/ledapsSrc/scripts/do_ledaps.py $BIN
RUN cp /usr/local/espa-surface/ledaps/ledapsSrc/scripts/ncdump $BIN
