# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'json'

vagrantfileApiVersion ||= "2"
confFile = File.expand_path(File.dirname(__FILE__)) + "/config.json"

Vagrant.require_version '>= 1.9.8'

def virtualMachineSettings(config, settings)
    config.vm.box = settings["box"] ||= "geerlingguy/centos7"
    config.vm.hostname = settings["hostname"]
    config.vm.network "private_network", ip: settings["ip"]
    
    if settings.include? 'portForwarding'
        settings["portForwarding"].each do |port|
            config.vm.network "forwarded_port", guest: port["guest"], host: port["host"], auto_correct: true
        end
    end
    
    if settings.include? 'folder'
        config.vm.synced_folder settings["folder"], "/vagrant"
    end
    
    # Configure VirtualBox Settings
    config.vm.provider "virtualbox" do |vb|
        vb.name = settings["hostname"]
        vb.customize ["modifyvm", :id, "--memory", settings["memory"] ||= "1024"]
        vb.customize ["modifyvm", :id, "--cpus", settings["cpus"] ||= "1"]
    end
end

def prepareMachine(config, settings)
    config.vm.provision "shell", inline: <<EOS
echo "* Add hosts ..."
cat > /etc/hosts <<EOF
#{settings['ansible']['ip']} #{settings['ansible']['hostname']} ansible
#{settings['jenkins']['ip']} #{settings['jenkins']['hostname']} jenkins
#{settings['nagios']['ip']} #{settings['nagios']['hostname']} nagios
#{settings['docker']['ip']} #{settings['docker']['hostname']} docker

EOF

echo "* SELinux in permisive mode ..."
setenforce 0

echo "* Add epel-release ..."
yum install -y epel-release

echo "* Update the OS ..."
yum update -y
EOS
end

Vagrant.configure(vagrantfileApiVersion) do |config|
    if File.exist? confFile then
        settings = JSON.parse(File.read(confFile))
    else
        abort "config settings file not found"
    end
    
    # Set The VM Provider
    ENV['VAGRANT_DEFAULT_PROVIDER'] = "virtualbox"
    
    config.vm.define "jenkins" do |jenkins|
        virtualMachineSettings(jenkins, settings["jenkins"])
        prepareMachine(jenkins, settings)
    end

    config.vm.define "nagios" do |nagios|
        virtualMachineSettings(nagios, settings["nagios"])
        prepareMachine(nagios, settings)
    end

    config.vm.define "docker" do |docker|
        virtualMachineSettings(docker, settings["docker"])
        prepareMachine(docker, settings)
    end
    
    # Ansible must be last as it needs access to the previous machines
    config.vm.define "ansible" do |ansible|
        virtualMachineSettings(ansible, settings["ansible"])
        prepareMachine(ansible, settings)
        ansible.vm.provision "shell", inline: <<EOS
echo "* Install Ansible ..."
yum install -y ansible

echo "* Fill Ansible inventory in /etc/ansible/hosts ..."
cat > /etc/ansible/hosts <<EOF
[ansible]
#{settings['ansible']['ip']}

[jenkins]
#{settings['jenkins']['ip']}

[nagios]
#{settings['nagios']['ip']}

[docker]
#{settings['docker']['ip']}

[ldo-servers:children]
ansible
jenkins
nagios
docker

[all:vars]
ansible_connection = ssh
#ansible_ssh_user = vagrant
ansible_user = vagrant
ansible_ssh_pass = vagrant
remote_user = vagrant

EOF

echo "* Set Ansible configuration in /etc/ansible/ansible.cfg ..."
cat > /etc/ansible/ansible.cfg <<EOF
[defaults]
deprecation_warnings = False
host_key_checking = False
retry_files_enabled = True
retry_files_save_path = ~/.ansible-retry

[colors]
highlight = white
verbose = blue
warn = yellow
error = red
debug = dark gray
deprecate = red
skip = cyan
unreachable = red
ok = green
changed = bright purple
diff_add = green
diff_remove = red
diff_lines = yellow

EOF

echo "* Copy Ansible playbooks and roles in /playbooks ..."
cp -R /vagrant/playbooks /playbooks

echo "* Patch Ansible playbooks and roles ..."
cat > /playbooks/roles/nagios-install/defaults/main.yml <<EOF
nagios_admin_username: #{settings['nagios']['adminUsername']}
nagios_admin_password: #{settings['nagios']['adminPassword']}

EOF

cat > /playbooks/roles/nrpe/defaults/main.yml <<EOF
server_port: #{settings['nrpe']['port']}
allowed_hosts: #{settings['nrpe']['allowedHosts']}

EOF

cat > /playbooks/roles/nagios-hosts/defaults/main.yml <<EOF
hosts_list:
  - host_type: ansible-server
    host_name: #{settings['ansible']['hostname']}
    host_alias: Ansible server
    host_address: #{settings['ansible']['ip']}
  - host_type: docker-server
    host_name: #{settings['docker']['hostname']}
    host_alias: Docker server
    host_address: #{settings['docker']['ip']}
  - host_type: jenkins-server
    host_name: #{settings['jenkins']['hostname']}
    host_alias: Jenkins server
    host_address: #{settings['jenkins']['ip']}

EOF

cat > /playbooks/roles/nagios-host-groups/defaults/main.yml <<EOF
groups_list:
  - group_name: local
    group_alias: Local servers
    group_members: localhost
  - group_name: sshable
    group_alias: SSHable servers
    group_members: localhost,#{settings['ansible']['hostname']},#{settings['docker']['hostname']},#{settings['jenkins']['hostname']}
  - group_name: pingable
    group_alias: PINGable servers
    group_members: localhost,#{settings['ansible']['hostname']},#{settings['docker']['hostname']},#{settings['jenkins']['hostname']}
  - group_name: http80
    group_alias: HTTP port 80 servers
    group_members: localhost,#{settings['docker']['hostname']}
  - group_name: http8080
    group_alias: HTTP port 8080 servers
    group_members: #{settings['jenkins']['hostname']}
  - group_name: docker
    group_alias: Docker servers
    group_members: #{settings['docker']['hostname']}

EOF

cat > /playbooks/roles/jenkins/defaults/main.yml <<EOF
jenkins_home: /var/lib/jenkins
jenkins_admin_username: #{settings['jenkins']['adminUsername']}
jenkins_admin_password: #{settings['jenkins']['adminPassword']}
jenkins_process_user: jenkins
jenkins_process_group: jenkins
jenkins_jar_location: /opt/jenkins-cli.jar
jenkins_slave_host: #{settings['docker']['hostname']}
jenkins_java_args:
  - "-Djava.awt.headless=true"
  - "-Djenkins.install.runSetupWizard=false"
jenkins_plugins:
  - build-pipeline-plugin
  - ssh
  - log-parser
  - template-project
  - ssh-slaves
  - github
  - docker-workflow

EOF

echo "* Execute Ansible Playbooks ..."
ansible-playbook /playbooks/install-all.yml
EOS
    end
    
end

