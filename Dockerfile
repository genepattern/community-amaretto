# copyright 2017-2018 Regents of the University of California and the Broad Institute. All rights reserved.

FROM genepattern/docker-amaretto:0.3


COPY install_stuff.R /build/source/install_stuff.R

RUN mkdir /source && \
   cd /source && \
   git clone https://github.com/broadinstitute/Community-AMARETTO.git && \
   cd Community-AMARETTO && \
   git checkout Community_AMARETTO_for_GenePattern


# install_stuff.R builds and installs AMARETTO from source along with its dependencies   
RUN Rscript /build/source/install_stuff.R 

# the module files are set into /usr/local/bin/amaretto
COPY src/* /usr/local/bin/community-amaretto/ 

CMD ["Rscript", "/usr/local/bin/cogaps/run_gp_tutorial_module.R" ]

