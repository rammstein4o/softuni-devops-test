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

echo "#{settings['ansible']['ip']} #{settings['ansible']['hostname']} ansible" >> /etc/hosts
echo "#{settings['jenkins']['ip']} #{settings['jenkins']['hostname']} jenkins" >> /etc/hosts
echo "#{settings['nagios']['ip']} #{settings['nagios']['hostname']} nagios" >> /etc/hosts
echo "#{settings['docker']['ip']} #{settings['docker']['hostname']} docker" >> /etc/hosts

echo "* SELinux in permisive mode ..."
setenforce 0

echo "* Add epel-release ..."
yum install -y epel-release
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

echo "[ansible]" >> /etc/ansible/hosts
echo "#{settings['ansible']['ip']}" >> /etc/ansible/hosts

echo "[jenkins]" >> /etc/ansible/hosts
echo "#{settings['jenkins']['ip']}" >> /etc/ansible/hosts

echo "[nagios]" >> /etc/ansible/hosts
echo "#{settings['nagios']['ip']}" >> /etc/ansible/hosts

echo "[docker]" >> /etc/ansible/hosts
echo "#{settings['docker']['ip']}" >> /etc/ansible/hosts

echo "[ldo-servers:children]" >> /etc/ansible/hosts
echo "ansible" >> /etc/ansible/hosts
echo "jenkins" >> /etc/ansible/hosts
echo "nagios" >> /etc/ansible/hosts
echo "docker" >> /etc/ansible/hosts

echo "[all:vars]" >> /etc/ansible/hosts
echo "ansible_connection = ssh" >> /etc/ansible/hosts
echo "#ansible_ssh_user = vagrant" >> /etc/ansible/hosts
echo "ansible_user = vagrant" >> /etc/ansible/hosts
echo "ansible_ssh_pass = vagrant" >> /etc/ansible/hosts
echo "remote_user = vagrant" >> /etc/ansible/hosts

echo "* Set Ansible configuration in /etc/ansible/ansible.cfg ..."

echo "[defaults]" > /etc/ansible/ansible.cfg
echo "deprecation_warnings = False" >> /etc/ansible/ansible.cfg
echo "host_key_checking = False" >> /etc/ansible/ansible.cfg
echo "retry_files_enabled = True" >> /etc/ansible/ansible.cfg
echo "retry_files_save_path = ~/.ansible-retry" >> /etc/ansible/ansible.cfg

echo "[colors]" >> /etc/ansible/ansible.cfg
echo "highlight = white" >> /etc/ansible/ansible.cfg
echo "verbose = blue" >> /etc/ansible/ansible.cfg
echo "warn = yellow" >> /etc/ansible/ansible.cfg
echo "error = red" >> /etc/ansible/ansible.cfg
echo "debug = dark gray" >> /etc/ansible/ansible.cfg
echo "deprecate = red" >> /etc/ansible/ansible.cfg
echo "skip = cyan" >> /etc/ansible/ansible.cfg
echo "unreachable = red" >> /etc/ansible/ansible.cfg
echo "ok = green" >> /etc/ansible/ansible.cfg
echo "changed = bright purple" >> /etc/ansible/ansible.cfg
echo "diff_add = green" >> /etc/ansible/ansible.cfg
echo "diff_remove = red" >> /etc/ansible/ansible.cfg
echo "diff_lines = yellow" >> /etc/ansible/ansible.cfg

echo "* Copy Ansible playbooks and roles in /playbooks ..."
cp -R /vagrant/playbooks /playbooks

echo "* Patch Ansible playbooks and roles ..."
echo "nagios_admin_username: #{settings['nagios']['adminUsername']}" > /playbooks/roles/nagios-install/defaults/main.yml
echo "nagios_admin_password: #{settings['nagios']['adminPassword']}" >> /playbooks/roles/nagios-install/defaults/main.yml

echo "hosts_list:" > /playbooks/roles/nagios-hosts/defaults/main.yml
echo "  - host_type: ansible-server" >> /playbooks/roles/nagios-hosts/defaults/main.yml
echo "    host_name: #{settings['ansible']['hostname']}" >> /playbooks/roles/nagios-hosts/defaults/main.yml
echo "    host_alias: Ansible server" >> /playbooks/roles/nagios-hosts/defaults/main.yml
echo "    host_address: #{settings['ansible']['ip']}" >> /playbooks/roles/nagios-hosts/defaults/main.yml

echo "  - host_type: docker-server" >> /playbooks/roles/nagios-hosts/defaults/main.yml
echo "    host_name: #{settings['docker']['hostname']}" >> /playbooks/roles/nagios-hosts/defaults/main.yml
echo "    host_alias: Docker server" >> /playbooks/roles/nagios-hosts/defaults/main.yml
echo "    host_address: #{settings['docker']['ip']}" >> /playbooks/roles/nagios-hosts/defaults/main.yml

echo "  - host_type: jenkins-server" >> /playbooks/roles/nagios-hosts/defaults/main.yml
echo "    host_name: #{settings['jenkins']['hostname']}" >> /playbooks/roles/nagios-hosts/defaults/main.yml
echo "    host_alias: Jenkins server" >> /playbooks/roles/nagios-hosts/defaults/main.yml
echo "    host_address: #{settings['jenkins']['ip']}" >> /playbooks/roles/nagios-hosts/defaults/main.yml

echo "groups_list:" > /playbooks/roles/nagios-host-groups/defaults/main.yml
echo "  - group_name: local" >> /playbooks/roles/nagios-host-groups/defaults/main.yml
echo "    group_alias: Local servers" >> /playbooks/roles/nagios-host-groups/defaults/main.yml
echo "    group_members: localhost" >> /playbooks/roles/nagios-host-groups/defaults/main.yml

echo "  - group_name: sshable" >> /playbooks/roles/nagios-host-groups/defaults/main.yml
echo "    group_alias: SSHable servers" >> /playbooks/roles/nagios-host-groups/defaults/main.yml
echo "    group_members: localhost,#{settings['ansible']['hostname']},#{settings['docker']['hostname']},#{settings['jenkins']['hostname']}" >> /playbooks/roles/nagios-host-groups/defaults/main.yml

echo "  - group_name: pingable" >> /playbooks/roles/nagios-host-groups/defaults/main.yml
echo "    group_alias: PINGable servers" >> /playbooks/roles/nagios-host-groups/defaults/main.yml
echo "    group_members: localhost,#{settings['ansible']['hostname']},#{settings['docker']['hostname']},#{settings['jenkins']['hostname']}" >> /playbooks/roles/nagios-host-groups/defaults/main.yml

echo "  - group_name: http80" >> /playbooks/roles/nagios-host-groups/defaults/main.yml
echo "    group_alias: HTTP port 80 servers" >> /playbooks/roles/nagios-host-groups/defaults/main.yml
echo "    group_members: localhost,#{settings['docker']['hostname']}" >> /playbooks/roles/nagios-host-groups/defaults/main.yml

echo "  - group_name: http8080" >> /playbooks/roles/nagios-host-groups/defaults/main.yml
echo "    group_alias: HTTP port 8080 servers" >> /playbooks/roles/nagios-host-groups/defaults/main.yml
echo "    group_members: #{settings['jenkins']['hostname']}" >> /playbooks/roles/nagios-host-groups/defaults/main.yml

echo "  - group_name: docker" >> /playbooks/roles/nagios-host-groups/defaults/main.yml
echo "    group_alias: Docker servers" >> /playbooks/roles/nagios-host-groups/defaults/main.yml
echo "    group_members: #{settings['docker']['hostname']}" >> /playbooks/roles/nagios-host-groups/defaults/main.yml

echo "server_port: #{settings['nrpe']['port']}" > /playbooks/roles/nrpe/defaults/main.yml
echo "allowed_hosts: #{settings['nrpe']['allowedHosts']}" >> /playbooks/roles/nrpe/defaults/main.yml

cat > /playbooks/roles/jenkins/defaults/main.yml <<EOF
jenkins_home: /var/lib/jenkins
jenkins_admin_username: #{settings['jenkins']['adminUsername']}
jenkins_admin_password: #{settings['jenkins']['adminUsername']}
jenkins_process_user: jenkins
jenkins_process_group: jenkins
jenkins_jar_location: /opt/jenkins-cli.jar
jenkins_java_args:
  - "-Djava.awt.headless=true"
  - "-Djenkins.install.runSetupWizard=false"
EOF

echo "* Execute Ansible Playbooks ..."
ansible-playbook /playbooks/install-all.yml
EOS
    end
    
end

