FROM jboss/openjdk18-rhel7:1.1
ENV FUSE_JAVA_IMAGE_NAME="fuse7/fuse-java-openshift" \
    FUSE_JAVA_IMAGE_VERSION="1.3" \
    JOLOKIA_VERSION="1.5.0.redhat-1" \
    PROMETHEUS_JMX_EXPORTER_VERSION="0.3.1.redhat-00006" \
    PATH=$PATH:"/usr/local/s2i" \
    AB_JOLOKIA_PASSWORD_RANDOM="true" \
    AB_JOLOKIA_AUTH_OPENSHIFT="true" \
    JAVA_DATA_DIR="/deployments/data"
# Some version information
LABEL name="$FUSE_JAVA_IMAGE_NAME" \
      version="$FUSE_JAVA_IMAGE_VERSION" \
      maintainer="Dhiraj Bokde <dhirajsb@gmail.com>" \
      summary="Build and run Spring Boot-based integration applications" \
      description="Build and run Spring Boot-based integration applications" \
      com.redhat.component="fuse-java-openshift-container" \
      io.fabric8.s2i.version.maven="3.3.3-1.el7" \
      io.fabric8.s2i.version.jolokia="1.5.0.redhat-1" \
      io.fabric8.s2i.version.prometheus.jmx_exporter="0.3.1.redhat-00006" \
      io.k8s.description="Build and run Spring Boot-based integration applications" \
      io.k8s.display-name="Fuse for OpenShift" \
      io.openshift.tags="builder,java,fuse" \
      io.openshift.s2i.scripts-url="image:///usr/local/s2i" \
      io.openshift.s2i.destination="/tmp" \
      org.jboss.deployments-dir="/deployments" \
      com.redhat.deployments-dir="/deployments" \
      com.redhat.dev-mode="JAVA_DEBUG:false" \
      com.redhat.dev-mode.port="JAVA_DEBUG_PORT:5005"
# Temporary switch to root
USER root
# Install Maven via SCL
COPY jboss.repo /etc/yum.repos.d/jboss.repo
RUN yum --disableplugin=subscription-manager install -y --enablerepo=jboss-rhel-rhscl rh-maven33-maven \
    && yum update -y \
    && yum clean all \
    && ln -s /opt/rh/rh-maven33/root/bin/mvn /usr/local/bin/mvn \
    && rm /etc/yum.repos.d/jboss.repo
# Use /dev/urandom to speed up startups.
RUN echo securerandom.source=file:/dev/urandom >> /usr/lib/jvm/java/jre/lib/security/java.security \
 && usermod -g root -G jboss jboss
# Prometheus JMX exporter agent
COPY "artifacts/io/prometheus/jmx/jmx_prometheus_javaagent/${PROMETHEUS_JMX_EXPORTER_VERSION}/jmx_prometheus_javaagent-${PROMETHEUS_JMX_EXPORTER_VERSION}.jar" /opt/prometheus/jmx_prometheus_javaagent.jar
RUN mkdir -p /opt/prometheus/etc
COPY prometheus-opts /opt/prometheus/prometheus-opts
COPY prometheus-config.yml /opt/prometheus/prometheus-config.yml
RUN chmod 444 /opt/prometheus/jmx_prometheus_javaagent.jar \
&& chmod 444 /opt/prometheus/prometheus-config.yml \
&& chmod 755 /opt/prometheus/prometheus-opts \
&& chmod 775 /opt/prometheus/etc \
&& chgrp root /opt/prometheus/etc
EXPOSE 9779
# Jolokia agent
RUN mkdir -p /opt/jolokia/etc
COPY "artifacts/org/jolokia/jolokia-jvm/${JOLOKIA_VERSION}/jolokia-jvm-${JOLOKIA_VERSION}-agent.jar" /opt/jolokia/jolokia.jar
#COPY "jolokia-jvm-${JOLOKIA_VERSION}-agent.jar" /opt/jolokia/jolokia.jar
ADD jolokia-opts /opt/jolokia/jolokia-opts
RUN chmod 444 /opt/jolokia/jolokia.jar \
 && chmod 755 /opt/jolokia/jolokia-opts \
 && chmod 775 /opt/jolokia/etc \
 && chgrp root /opt/jolokia/etc
EXPOSE 8778
# S2I scripts + README
COPY s2i /usr/local/s2i
RUN chmod 755 /usr/local/s2i/*
ADD README.md /usr/local/s2i/usage.txt
# Add run script as /opt/run-java/run-java.sh and make it executable
COPY run-java.sh /opt/run-java/
RUN chmod 755 /opt/run-java/run-java.sh
# Adding run-env.sh to set app dir
COPY run-env.sh /opt/run-java/run-env.sh
RUN chmod 755 /opt/run-java/run-env.sh
# Copy licenses
RUN mkdir -p /opt/fuse/licenses
COPY licenses.css /opt/fuse/licenses
COPY licenses.xml /opt/fuse/licenses
COPY licenses.html /opt/fuse/licenses
COPY apache_software_license_version_2.0-apache-2.0.txt /opt/fuse/licenses
# Necessary to permit running with a randomised UID
RUN mkdir -p /deployments/data \
 && chmod -R "g+rwX" /deployments \
 && chown -R jboss:root /deployments \
 && chmod -R "g+rwX" /home/jboss \
 && chown -R jboss:root /home/jboss \
 && chmod 664 /etc/passwd
# S2I requires a numeric, non-0 UID. This is the UID for the jboss user in the base image
USER 185
RUN mkdir -p /home/jboss/.m2
COPY settings.xml /home/jboss/.m2/settings.xml

EXPOSE 8084
# Use the run script as default since we are working as an hybrid image which can be
# used directly to. (If we were a plain s2i image we would print the usage info here)
CMD [ "/usr/local/s2i/run" ]

