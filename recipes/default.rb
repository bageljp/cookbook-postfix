#
# Cookbook Name:: postfix
# Recipe:: default
#
# Copyright 2014, bageljp
#
# All rights reserved - Do Not Redistribute
#

package "postfix"

template "/etc/postfix/main.cf" do
  owner "root"
  group "root"
  mode 00644
  notifies :restart, "service[postfix]"
end

if node['postfix']['ses']['use']
  package "cyrus-sasl-plain"

  bash "create sasl_passwd.db" do
    user "root"
    group "root"
    code "postmap hash:/etc/postfix/sasl_passwd"
    notifies :restart, "service[postfix]"
    action :nothing
  end

  template "/etc/postfix/sasl_passwd" do
    owner "root"
    group "root"
    mode 00644
    notifies :run, 'bash[create sasl_passwd.db]', :immediately
  end
end

case node['platform_family']
when "rhel", "fedora"
  service "sendmail" do
    action :nothing
  end

  bash "switch_mta_to_postfix" do
    user "root"
    group "root"
    code "/usr/sbin/alternatives --set mta /usr/sbin/sendmail.postfix"
    notifies :stop, "service[sendmail]"
    notifies :start, "service[postfix]"
    not_if "/usr/bin/test /etc/alternatives/mta -ef /usr/sbin/sendmail.postfix"
  end
end

service "postfix" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end

