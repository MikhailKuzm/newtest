FROM debian:testing

LABEL org.label-schema.license="GPL-2.0" \
      org.label-schema.vcs-url="https://github.com/rocker-org/r-base" \
      org.label-schema.vendor="Rocker Project" \
      maintainer="Dirk Eddelbuettel <edd@debian.org>"

## Set a default user. Available via runtime flag `--user docker`
## Add user to 'staff' group, granting them write privileges to /usr/local/lib/R/site.library
## User should also have & own a home directory (for rstudio or linked volumes to work properly).
RUN useradd user1 \
	&& mkdir /home/newdocker \
	&& chown user1:newdocker /home/newdocker \
	&& addgroup user1 staff


RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		ca-certificates \
		ed \
		fonts-texgyre \
		less \
		locales \
		vim-tiny \
		wget \
	&& rm -rf /var/lib/apt/lists/*

## Configure default locale, see https://github.com/rocker-org/rocker/issues/19
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
	&& locale-gen en_US.utf8 \
	&& /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

## Use Debian unstable via pinning -- new style via APT::Default-Release
RUN echo "deb http://http.debian.net/debian sid main" > /etc/apt/sources.list.d/debian-unstable.list \
        && echo 'APT::Default-Release "testing";' > /etc/apt/apt.conf.d/default

ENV R_BASE_VERSION 4.0.2

## Now install R and littler, and create a link for littler in /usr/local/bin
RUN apt-get update \
        && apt-get install -t unstable -y --no-install-recommends \
                gcc-9-base \
                libopenblas0-pthread \
		littler \
                r-cran-littler \
		r-base=${R_BASE_VERSION}-* \
		r-base-dev=${R_BASE_VERSION}-* \
		r-recommended=${R_BASE_VERSION}-* \
	&& ln -s /usr/lib/R/site-library/littler/examples/build.r /usr/local/bin/build.r \
	&& ln -s /usr/lib/R/site-library/littler/examples/check.r /usr/local/bin/check.r \
	&& ln -s /usr/lib/R/site-library/littler/examples/install.r /usr/local/bin/install.r \
	&& ln -s /usr/lib/R/site-library/littler/examples/install2.r /usr/local/bin/install2.r \
	&& ln -s /usr/lib/R/site-library/littler/examples/installBioc.r /usr/local/bin/installBioc.r \
	&& ln -s /usr/lib/R/site-library/littler/examples/installGithub.r /usr/local/bin/installGithub.r \
	&& ln -s /usr/lib/R/site-library/littler/examples/testInstalled.r /usr/local/bin/testInstalled.r \
	&& install.r docopt \
	&& rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
	&& rm -rf /var/lib/apt/lists/*
  
RUN sudo R -e "install.packages('rmarkdown', repos='http://cran.rstudio.com/')" \
&& R -e "install.packages(c('shiny'), repos='http://cran.rstudio.com/')" \
&& R -e "install.packages(c('dplyr'), repos='http://cran.rstudio.com/')" \
&& R -e "install.packages(c('data.table'), repos='http://cran.rstudio.com/')" \
&& R -e "install.packages(c('RPostgres'), repos='http://cran.rstudio.com/')" \
&& R -e "install.packages(c('ggolot2'), repos='http://cran.rstudio.com/')" \
&& R -e "install.packages(c('datasets'), repos='http://cran.rstudio.com/')" 

VOLUME  /home/newdocker
EXPOSE 1111
USER user1
CMD ["R", "-e shiny::runApp('/home/newdocker',port=1111,host='0.0.0.0')"]
