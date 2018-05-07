FROM ubuntu:16.04

MAINTAINER Maria Luiza Mondelli <malumondelli@gmail.com>

RUN apt-get update

RUN apt-get install -y \
	sqlite3 \
	git \
	wget \
	mafft \
	raxml \
	software-properties-common \
	gdebi-core \
	time \
	libssl1.0.0 \
	vim \
	python-pip
	
# ==================
# JAVA =============
# ==================

ENV JAVA_VERSION 8u91
ENV JAVA_HOME /usr/lib/jvm/jdk1.8.0_111/
COPY util/jdk-8u111-linux-x64.tar.gz /usr/lib/jvm/
WORKDIR /usr/lib/jvm
RUN tar -zxvf jdk-8u111-linux-x64.tar.gz 
#&& \ rm jdk-8u111-linux-x64.tar.gz
ENV PATH "$PATH":/${JAVA_HOME}/bin:.:

# ==================
# R PACKAGES =======
# ==================

RUN sh -c 'echo "deb http://cran.rstudio.com/bin/linux/ubuntu trusty/" >> /etc/apt/sources.list'
RUN gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9
RUN gpg -a --export E084DAB9 | apt-key add -

RUN apt-get update

RUN apt-get install -y r-base

RUN R -e "install.packages(c('shiny', 'rmarkdown', 'ggplot2', 'sqldf', 'formattable', 'RColorBrewer', 'shinydashboard', 'DT', 'plyr', 'dplyr', 'reshape', 'lubridate', 'scales', 'anytime', 'shinyjs'), repos='https://cloud.r-project.org/')"

# ==================
# SHINY ============
# ==================

RUN apt-get install -y \
    gdebi-core \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    libssl-dev

# Download and install shiny server
RUN wget --no-verbose https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/VERSION -O "version.txt" && \
    VERSION=$(cat version.txt)  && \
    wget --no-verbose "https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/shiny-server-$VERSION-amd64.deb" -O ss-latest.deb && \
    gdebi -n ss-latest.deb && \
    rm -f version.txt ss-latest.deb

# ==================
# SWIFT ============
# ==================

RUN cd /usr/local; wget http://swift-lang.org/packages/swift-0.96.2.tar.gz && \
    tar xvfz /usr/local/swift-0.96.2.tar.gz 
ENV SWIFT /usr/local/swift-0.96.2
ENV PATH "$PATH":/${SWIFT}/bin:.:
COPY util/swiftlog /usr/local/swift-0.96.2/bin/
COPY util/schema_sqlite.sql /usr/local/swift-0.96.2/etc/provenance/

# ==================
# SWIFT-PHYLO ======
# ==================

RUN cd /root; git clone https://github.com/mmondelli/swift-phylo.git
ENV SWIFT_PHYLO /root/swift-phylo/bin 
ENV PATH "$PATH":/${SWIFT_PHYLO}:.:

# ==================
# SWIFT-GECKO ======
# ==================

RUN cd /root; git clone https://github.com/mmondelli/swift-gecko.git
ENV SWIFT_GECKO /root/swift-gecko
ENV PATH "$PATH":/${SWIFT_GECKO}/bin:.:

# ==================
# RASFLOW ==========
# ==================

RUN cd /root; git clone https://github.com/mmondelli/rasflow.git
ENV RASFLOW /root/rasflow
ENV PATH "$PATH":/${RASFLOW}/bin:.:
RUN mv /root/rasflow/workbench /srv/shiny-server/

# TABIX E BGZIP ====

RUN cd /usr/local; wget https://sourceforge.net/projects/samtools/files/tabix/tabix-0.2.6.tar.bz2 && \
     tar xjvf tabix-0.2.6.tar.bz2; cd tabix-0.2.6; make
ENV PATH "$PATH":/usr/local/tabix-0.2.6:.:

# VCF TOOLS ========

RUN cd /usr/local; wget https://sourceforge.net/projects/vcftools/files/vcftools_0.1.13.tar.gz && \
	tar xvfz vcftools_0.1.13.tar.gz; cd vcftools_0.1.13; make 
ENV PATH "$PATH":/usr/local/vcftools_0.1.13/bin:.:
ENV PERL5LIB "$PERL5LIB":/usr/local/vcftools_0.1.13/lib/perl5/site_perl:

# BOWTIE 2.1.0 =====

RUN cd /usr/local; wget https://sourceforge.net/projects/bowtie-bio/files/bowtie2/2.1.0/bowtie2-2.1.0-linux-x86_64.zip && \
	unzip bowtie2-2.1.0-linux-x86_64.zip 
ENV PATH "$PATH":/usr/local/bowtie2-2.1.0:.:

# ==================
# SAMTOOLS =========
# ==================

#RUN cd /usr/local; wget https://sourceforge.net/projects/samtools/files/samtools/0.1.18/samtools-0.1.18.tar.bz2
#ENV SAMTOOLS /usr/local/swift-0.96.2
#ENV PATH "$PATH":/${SAMTOOLS}/bin:.:

# ==================
# PYTHON PACKAGES ==
# ==================

RUN pip install numpy scipy
RUN pip install biopython

# ==================
# FINAL CONFIG =====
# ==================

RUN apt-get install -y weka

WORKDIR /root

# ==================
# FINAL CONFIG =====
# ==================

EXPOSE 3838

COPY util/shiny-server.sh /usr/bin/shiny-server.sh
#COPY util/swift_provenance.db /srv/shiny-server/workbench/swift_provenance.db

RUN wget https://zenodo.org/record/1242591/files/swift_provenance.db.gz
RUN gunzip swift_provenance.db.gz
RUN mv swift_provenance.db /srv/shiny-server/workbench/swift_provenance.db

RUN chmod 777 /usr/bin/shiny-server.sh
RUN ln -s /srv/shiny-server/workbench/swift_provenance.db swift_provenance.db

RUN mkdir MachineLearningExperiments
COPY MachineLearningExperiments /root/MachineLearningExperiments

RUN mkdir util
COPY util/phylo_scale.db /root/util/
COPY util/phylo_scale.csv /root/util/

CMD ["/usr/bin/shiny-server.sh"]



