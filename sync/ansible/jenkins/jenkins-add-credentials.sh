#!/bin/bash

JENKINS_HOST=$1
JENKINS_USERNAME=$2
JENKINS_PASSWORD=$3

cat <<EOF | java -jar /opt/jenkins-cli.jar -s ${JENKINS_HOST} create-credentials-by-xml system::system::jenkins _ --username ${JENKINS_USERNAME} --password ${JENKINS_PASSWORD}
<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>                                      
<scope>GLOBAL</scope>
  <id>vagrant</id>
  <description>Vagrant username and password pair</description>
  <username>vagrant</username>
  <password>vagrant</password>                                                                                                            
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
EOF
