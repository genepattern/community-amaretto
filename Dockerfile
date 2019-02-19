# copyright 2017-2018 Regents of the University of California and the Broad Institute. All rights reserved.

#FROM genepattern/docker-amaretto:0.51
FROM r-base:3.5.2

RUN apt-get update  && \
    apt-get install -t unstable libssl-dev  --yes && \
    apt-get install libxml2-dev --yes && \
    apt-get install libcurl4-gnutls-dev --yes && \
    apt-get update && apt-get install -y --no-install-recommends apt-utils && \
    apt-get install libxml2-dev -y && \
    apt-get install libcairo2-dev -y && \
    apt-get install  xvfb xauth xfonts-base libxt-dev -y && \
    apt-get install -y  -t unstable git && \
    apt-get install -t unstable -y libv8-dev && \
    rm -rf /var/lib/apt/lists/*


COPY install_stuff.R /build/source/install_stuff.R


# install_stuff.R builds and installs AMARETTO from source along with its dependencies   
RUN Rscript /build/source/install_stuff.R 

COPY install2.R /build/source/install2.R
RUN Rscript /build/source/install2.R

# the module files are set into /usr/local/bin/amaretto
COPY src/* /usr/local/bin/community-amaretto/ 

RUN apt-get update && apt-get install -t unstable pandoc --yes


CMD ["Rscript", "/usr/local/bin/cogaps/run_community_amaretto_module.R" ]

