#!/bin/bash

JENKINS_HOST=$1
JENKINS_USERNAME=$2
JENKINS_PASSWORD=$3
SLAVE_HOST=$4
CREDENTIALS_ID=$5

cat <<EOF | java -jar /opt/jenkins-cli.jar -s ${JENKINS_HOST} create-node ${SLAVE_HOST} --username ${JENKINS_USERNAME} --password ${JENKINS_PASSWORD}
<slave>
  <name>${SLAVE_HOST}</name>
  <description>Jenkins Slave Node</description>
  <remoteFS>/vagrant</remoteFS>
  <numExecutors>1</numExecutors>
  <mode>NORMAL</mode>
  <retentionStrategy class="hudson.slaves.RetentionStrategy$Always"/>
  <launcher class="hudson.plugins.sshslaves.SSHLauncher" plugin="ssh-slaves@1.5">
    <host>${SLAVE_HOST}</host>
    <port>22</port>
    <credentialsId>${CREDENTIALS_ID}</credentialsId>
  </launcher>
  <label>docker</label>
  <nodeProperties/>
  <userId>${JENKINS_USERNAME}</userId>
</slave>
EOF
