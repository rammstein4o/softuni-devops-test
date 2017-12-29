#!/bin/bash

function random_string
{
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-32} | head -n 1
}

TIMESTAMP=$(date +%s);
TIMESTAMP="${TIMESTAMP}000"
SALT=$(random_string 6);
TOKEN=$(random_string 32);
TOKEN="${TOKEN}${SALT}";
TOKEN=$(echo -n "${TOKEN}" | base64);
USERNAME=${1};
PASSWORD=${2};
JENKINS_HOME=${3};
PASSWORD_HASH=$(echo -n "${PASSWORD}{${SALT}}" | sha256sum);
PASSWORD_HASH=${PASSWORD_HASH::-1}
PASSWORD_HASH=${PASSWORD_HASH// }
PASSWORD_HASH="${SALT}:${PASSWORD_HASH}"

USERS_PATH="${JENKINS_HOME}/users";
CURRENT_USER_PATH="${USERS_PATH}/${USERNAME}";
CURRENT_USER_CONFIG="${CURRENT_USER_PATH}/config.xml";

PROCESS_USER=${4};
PROCESS_GROUP=${5};

mkdir -p ${CURRENT_USER_PATH};

cat > ${CURRENT_USER_CONFIG} <<EOF
<?xml version='1.0' encoding='UTF-8'?>
<user>
  <fullName>${USERNAME}</fullName>
  <properties>
    <jenkins.security.ApiTokenProperty>
      <apiToken>{${TOKEN}}</apiToken>
    </jenkins.security.ApiTokenProperty>
    <hudson.model.MyViewsProperty>
      <views>
        <hudson.model.AllView>
          <owner class="hudson.model.MyViewsProperty" reference="../../.."/>
          <name>all</name>
          <filterExecutors>false</filterExecutors>
          <filterQueue>false</filterQueue>
          <properties class="hudson.model.View$PropertyList"/>
        </hudson.model.AllView>
      </views>
    </hudson.model.MyViewsProperty>
    <hudson.model.PaneStatusProperties>
      <collapsed/>
    </hudson.model.PaneStatusProperties>
    <hudson.search.UserSearchProperty>
      <insensitiveSearch>true</insensitiveSearch>
    </hudson.search.UserSearchProperty>
    <hudson.security.HudsonPrivateSecurityRealm_-Details>
      <passwordHash>${PASSWORD_HASH}</passwordHash>
    </hudson.security.HudsonPrivateSecurityRealm_-Details>
    <jenkins.security.LastGrantedAuthoritiesProperty>
      <roles>
        <string>authenticated</string>
      </roles>
      <timestamp>${TIMESTAMP}</timestamp>
    </jenkins.security.LastGrantedAuthoritiesProperty>
  </properties>
</user>
EOF

chown -R ${PROCESS_USER}:${PROCESS_GROUP} ${USERS_PATH};

exit 0;
