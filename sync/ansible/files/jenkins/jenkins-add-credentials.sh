#!/bin/bash

# 
# Create Jenkins credentials
# 

java -jar /opt/jenkins-cli.jar -s http://localhost:8080/ -remoting login --username admin --password admin && echo '<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>                                      
<scope>GLOBAL</scope>
  <id>vagrant</id>
  <description>Vagrant username and password pair</description>
  <username>vagrant</username>
  <password>vagrant</password>                                                                                                            
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>' | java -jar /opt/jenkins-cli.jar -s http://localhost:8080/ -remoting create-credentials-by-xml system::system::jenkins _
