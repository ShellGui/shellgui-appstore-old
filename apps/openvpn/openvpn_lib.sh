#!/bin/sh

install_openvpn_dependence()
{
if
echo "$OS" | grep -iq "centos"
then
(yum update -y && yum install -y lzo lzo-devel pam-devel 2>&1) || exit 1
fi
if
echo "$OS" | grep -iq "ubuntu"
then
(apt-get update --fix-missing && apt-get install -y liblzo2-dev libpam0g-dev 2>&1) || exit 1
fi
if
echo "$OS" | grep -iq "debian"
then
(apt-get update --fix-missing && apt-get install -y liblzo2-dev libpam0g-dev 2>&1) || exit 1
fi
}

download_openvpn()
{
export download_json='{
"file_name":"openvpn-2.3.5.tar.gz",
"downloader":"aria2 curl wget",
"save_dest":"$DOCUMENT_ROOT/../sources/openvpn-2.3.5.tar.gz",
"useragent":"Mozilla/4.0 (compatible; MSIE 6.1; Windows XP)",
"timeout":20,
"md5sum":"4422fe0b6ba898a4df6411fe3cc2d2f8",
	"download_urls":{
	"swupdate.openvpn.org":"http://swupdate.openvpn.org/community/releases/openvpn-2.3.5.tar.gz"
	}
}'
main.sbin download

export download_json='{
"file_name":"EasyRSA-2.2.2.tgz",
"downloader":"aria2 curl wget",
"save_dest":"$DOCUMENT_ROOT/../sources/EasyRSA-2.2.2.tgz",
"useragent":"Mozilla/4.0 (compatible; MSIE 6.1; Windows XP)",
"timeout":20,
"md5sum":"8b6002af8bfc217e0290a172d24e0c26",
	"download_urls":{
	"swupdate.openvpn.org":"https://github.com/OpenVPN/easy-rsa/releases/download/2.2.2/EasyRSA-2.2.2.tgz"
	}
}'
main.sbin download


}

make_openvpn()
{
cd $DOCUMENT_ROOT/../sources/
rm -rf openvpn-2.3.5
tar zxvf openvpn-2.3.5.tar.gz
cd openvpn-2.3.5
./configure --prefix=/usr/local/openvpn
make
make install

}
config_openvpn()
{
cd $DOCUMENT_ROOT/../sources/openvpn-2.3.5
mkdir /etc/openvpn/
cd $DOCUMENT_ROOT/../sources/
rm -rf EasyRSA-2.2.2
tar zxvf EasyRSA-2.2.2.tgz
cp -R EasyRSA-2.2.2 /etc/openvpn/easy-rsa
cp -R /etc/openvpn/easy-rsa/openssl-1.0.0.cnf /etc/openvpn/easy-rsa/openssl.cnf
useradd openvpn
cat <<EOF > /etc/openvpn/openvpn.conf
mode server
tls-server

### network options
port 1194
proto udp
dev tun

### Certificate and key files
ca /etc/openvpn/easy-rsa/keys/ca.crt
cert /etc/openvpn/easy-rsa/keys/server.crt
key /etc/openvpn/easy-rsa/keys/server.key
dh /etc/openvpn/easy-rsa/keys/dh2048.pem

client-to-client
server 10.0.0.0 255.255.255.0
push "redirect-gateway def1"
push "dhcp-option DNS 192.168.2.1" # Change this to your router's LAN IP Address
push "route 192.168.2.0 255.255.255.0" # Change this to your network

### (optional) compression (Can be slow)
#comp-lzo

persist-key
persist-tun

verb 3
keepalive 10 120
log-append /var/log/openvpn/openvpn.log

EOF

}

do_install_openvpn()
{
check_openvpn_installed && echo "openvpn binary installed" && exit 1
touch $DOCUMENT_ROOT/../tmp/openvpn_ins_detail.log
main.sbin pregress_schedule option="add" task="_PS_Install_openvpn" schedule="{\"_PS_1_Download_Sources\":\"0\",\"_PS_2_Make_install_OpenVPN_Dependence\":\"0\",\"_PS_3_Make_install_OpenVPN\":\"0\",\"_PS_4_Config_OpenVPN\":\"0\",\"_PS_5_OpenVPN_finished_Installtion\":\"0\"}" detail_file="$DOCUMENT_ROOT/../tmp/openvpn_ins_detail.log" app="openvpn" status="working"
main.sbin pregress_schedule option="change_pregress" task="_PS_Install_openvpn" pregress_now="10"
main.sbin pregress_schedule option="now" task="_PS_Install_openvpn" schedule_now="_PS_1_Download_Sources"

main.sbin pregress_schedule option="change_pregress" task="_PS_Install_openvpn" pregress_now="30"
download_openvpn > $DOCUMENT_ROOT/../tmp/openvpn_ins_detail.log 2>&1
if
[ $? -ne 0 ]
then
main.sbin pregress_schedule option="change_status" task="_PS_Install_openvpn" status_now="fail"
exit 1
fi

main.sbin pregress_schedule option="now" task="_PS_Install_openvpn" schedule_now="_PS_2_Make_install_OpenVPN_Dependence"
main.sbin pregress_schedule option="change_pregress" task="_PS_Install_openvpn" pregress_now="45"
install_openvpn_dependence > $DOCUMENT_ROOT/../tmp/openvpn_ins_detail.log 2>&1

main.sbin pregress_schedule option="now" task="_PS_Install_openvpn" schedule_now="_PS_3_Make_install_OpenVPN"
main.sbin pregress_schedule option="change_pregress" task="_PS_Install_openvpn" pregress_now="60"
make_openvpn >> $DOCUMENT_ROOT/../tmp/openvpn_ins_detail.log 2>&1
if
[ $? -ne 0 ]
then
main.sbin pregress_schedule option="change_status" task="_PS_Install_openvpn" status_now="fail"
exit 1
fi

main.sbin pregress_schedule option="now" task="_PS_Install_openvpn" schedule_now="_PS_4_Config_OpenVPN"
main.sbin pregress_schedule option="change_pregress" task="_PS_Install_openvpn" pregress_now="80"
config_openvpn >> $DOCUMENT_ROOT/../tmp/openvpn_ins_detail.log 2>&1
main.sbin pregress_schedule option="now" task="_PS_Install_openvpn" schedule_now="_PS_5_OpenVPN_finished_Installtion"
main.sbin pregress_schedule option="now" task="_PS_Install_openvpn" schedule_now="_PS_5_OpenVPN_finished_Installtion"
main.sbin pregress_schedule option="change_pregress" task="_PS_Install_openvpn" pregress_now="100"
main.sbin pregress_schedule option="change_status" task="_PS_Install_openvpn" status_now="success"

}

check_openvpn_installed()
{
if
[ -x /usr/local/openvpn/sbin/openvpn ]
then
return 0
else
return 1
fi
}
install_openvpn()
{
check_openvpn_installed ||[ "$(main.sbin pregress_schedule option="get_status" task="_PS_Install_openvpn" | grep -Po '[\w]*')" = "working" ] || rm -f $DOCUMENT_ROOT/../tmp/openvpn_ins_detail.log
[ -f $DOCUMENT_ROOT/../tmp/openvpn_ins_detail.log ] || do_install_openvpn &
. $DOCUMENT_ROOT/apps/notice/notice_lib.sh
FORM_ps="_PS_Install_openvpn"
get_pregress_schedule_notice_detail
}
pre_openvpn_install_config()
{
(echo "Success save,you can install now" | main.sbin output_json 0) || exit 0
}
pre_install_openvpn()
{
echo "$_LANG_Ready_to_Install"

}

############################
get_ssl_detail()
{
[ -f $1 ] || return 1
decode_str=`openssl x509 -in $1 -inform pem -noout -text -nameopt multiline,-esc_msb | sed '/Issuer:/,/emailAddress/d'| grep -E "Public-Key:|emailAddress.*=|countryName.*=|stateOrProvinceName.*=|localityName.*=|organizationName.*=|organizationalUnitName.*=|commonName.*=|Not After|Not Before" | sort -n | uniq |sed 's/^[ ][ ]*//g'`
V_START=`echo "$decode_str" | grep "Not Before" | sed 's/Not Before[ ]*:[ ]*//'`
V_END=`echo "$decode_str" | grep "Not After" | sed 's/Not After[ ]*:[ ]*//'`
I_DN_C=`echo "$decode_str" | grep "countryName" | awk -F " = " {'print $2'}`
S_DN_ST=`echo "$decode_str" | grep "stateOrProvinceName" | awk -F " = " {'print $2'}`
S_DN_L=`echo "$decode_str" | grep "localityName" | awk -F " = " {'print $2'}`
S_DN_O=`echo "$decode_str" | grep "organizationName" | awk -F " = " {'print $2'}`
S_DN_OU=`echo "$decode_str" | grep "organizationalUnitName" | awk -F " = " {'print $2'}`
S_DN_CN=`echo "$decode_str" | grep "commonName" | awk -F " = " {'print $2'}`
KEY_EMAIL=`echo "$decode_str" | grep "emailAddress" | awk -F " = " {'print $2'}`
remaining_day=$(expr $(expr $(date -d "$V_END" +%s) - $(date +%s)) / 86400)
key_size=`echo "$decode_str" | grep "Public-Key:" | grep -Po '[0-9]*'`
if
[ $remaining_day -gt 90 ]
then
color="success"
Tip="$_LANG_Distance_expired $remaining_day $_LANG_Days_left"
elif
[ $remaining_day -lt 90 ] && [ $remaining_day -gt 10 ]
then
color="warning"
Tip="$_LANG_Distance_expired $remaining_day $_LANG_Days_left"
elif
color="danger"
[ $remaining_day -lt 10 ]
then
Tip="$remaining_day $_LANG_Days_out"
fi

}
get_ssl_detail_html()
{
cat <<'EOF'
<script>
$(function(){
  $('#build').on('submit', function(e){
    e.preventDefault();
    var data = "app=openvpn&"+$(this).serialize();
    var url = 'index.cgi';
    Ha.common.ajax(url, 'json', data, 'post', 'ajax-proxy');
  });
});
</script>
EOF
client_ssl_edit()
{
cat <<EOF

<p class="bg-$color">$_LANG_Build_on $V_START
$_LANG_Overdue_on $V_END
$Tip
</p>

<form id="build">
<table class="table">
<tr>
<td>
$_LANG_Country
</td>
<td>
<input class="form-control" placeholder="Country" name="SSL_C" value="$I_DN_C">
</td>
</tr>
<tr>
<td>
$_LANG_Provinces
</td>
<td>
<input class="form-control" placeholder="State" name="SSL_ST" value="$S_DN_ST">
</td>
</tr>
<tr>
<td>
$_LANG_City
</td>
<td>
<input class="form-control" placeholder="Location" name="SSL_L" value="$S_DN_L">
</td>
</tr>
<tr>
<td>
$_LANG_Organization
</td>
<td>
<input class="form-control" placeholder="Organization" name="SSL_O" value="$S_DN_O">
</td>
</tr>
<tr>
<td>
$_LANG_Organizational_unit
</td>
<td>
<input class="form-control" placeholder="Organizational Unit" name="SSL_OU" value="$S_DN_OU">
</td>
</tr>
<tr>
<td>
$_LANG_Common_name
</td>
<td>
<input class="form-control" placeholder="Common Name" name="SSL_CN" value="$S_DN_CN">
</td>
</tr>
<tr>
<td>
E-Mail
</td>
<td>
<input class="form-control" placeholder="Common Name" name="KEY_EMAIL" value="$KEY_EMAIL">
</td>
</tr>
<tr>
<td>
$_LANG_Guarantee
</td>
<td>
<div class="row">
	<div class="col-md-6">
<input class="form-control" placeholder="Common Name" name="SSL_Guarantee" value="$remaining_day">
	</div>
	<div class="col-md-6">
	$_LANG_Days
	</div>
</div>
</td>
</tr>
<tr>
<td>
当前证书大小
</td>
<td>
$key_size
</td>
</tr>
<tr>
<td>
$_LANG_Option
</td>
<td>
<input type="hidden" name="action" value="build">
<input type="hidden" name="file" value="$FORM_file">
<button class="btn btn-primary" id="_submit" type="submit">$_LANG_Save</button>
</td>
</tr>
</table>
</form>
EOF
}

ca_server_ssl_edit()
{
eval `grep -E "^export PKCS11_PIN=|^export KEY_SIZE=|^export KEY_EXPIRE=" /etc/openvpn/easy-rsa/vars`

cat <<EOF

<p class="bg-$color">$_LANG_Build_on $V_START
$_LANG_Overdue_on $V_END
$Tip
</p>
<p class="bg-danger">ca将和server证书一起被修改，所有的client证书也即将重新生成</p>
<form id="build">
<table class="table">
<tr>
<td>
Default PIN
</td>
<td>
<input class="form-control" placeholder="Country" name="PKCS11_PIN" value="$PKCS11_PIN">
</td>
</tr>
<tr>
<td>
Default KEY_SIZE
</td>
<td>
<select class="form-control" name="KEY_SIZE">
	<option value="4096" `[ $KEY_SIZE -eq 4096 ] && echo "selected"`>4096</option>
	<option value="2048" `[ $KEY_SIZE -eq 2048 ] && echo "selected"`>2048</option>
	<option value="1024"`[ $KEY_SIZE -eq 1024 ] && echo "selected"` >1024</option>
</select>
</td>
</tr>
<tr>
<td>
Default KEY_EXPIRE
</td>
<td>
<input class="form-control" placeholder="Country" name="KEY_EXPIRE" value="$KEY_EXPIRE">
</td>
</tr>
<tr>
<td>
$_LANG_Country
</td>
<td>
<input class="form-control" placeholder="Country" name="SSL_C" value="$I_DN_C">
</td>
</tr>
<tr>
<td>
$_LANG_Provinces
</td>
<td>
<input class="form-control" placeholder="State" name="SSL_ST" value="$S_DN_ST">
</td>
</tr>
<tr>
<td>
$_LANG_City
</td>
<td>
<input class="form-control" placeholder="Location" name="SSL_L" value="$S_DN_L">
</td>
</tr>
<tr>
<td>
$_LANG_Organization
</td>
<td>
<input class="form-control" placeholder="Organization" name="SSL_O" value="$S_DN_O">
</td>
</tr>
<tr>
<td>
$_LANG_Organizational_unit
</td>
<td>
<input class="form-control" placeholder="Organizational Unit" name="SSL_OU" value="$S_DN_OU">
</td>
</tr>
<tr>
<td>
E-Mail
</td>
<td>
<input class="form-control" placeholder="Common Name" name="KEY_EMAIL" value="$KEY_EMAIL">
</td>
</tr>
<tr>
<td>
$_LANG_Guarantee
</td>
<td>
<div class="row">
	<div class="col-md-6">
<input class="form-control" placeholder="Common Name" name="SSL_Guarantee" value="$remaining_day">
	</div>
	<div class="col-md-6">
	$_LANG_Days
	</div>
</div>
</td>
</tr>
<tr>
<td>
当前证书大小
</td>
<td>
$key_size
</td>
</tr>
<tr>
<td>
$_LANG_Option
</td>
<td>
<input type="hidden" name="action" value="build">
<input type="hidden" name="file" value="$FORM_file">
<button class="btn btn-primary" id="_submit" type="submit">$_LANG_Save</button>
</td>
</tr>
</table>
</form>
EOF
}

[ -f /etc/openvpn/easy-rsa/keys/$FORM_file ] || return 1
get_ssl_detail /etc/openvpn/easy-rsa/keys/$FORM_file
if
echo $FORM_file | grep -qE "^ca.crt$|^server.crt$"
then
ca_server_ssl_edit
else
client_ssl_edit
fi
}

do_crt()
{
[ -z "$1" ] && return 1

cd /etc/openvpn/easy-rsa/
. ./vars
if
[ "$1" = "ca" ] ||[ "$1" = "server" ]
then
sed -i -e '/export PKCS11_MODULE_PATH=/d' \
		-e '/export PKCS11_PIN=/d' \
		-e '/export KEY_SIZE=/d' \
		-e '/export CA_EXPIRE=/d' \
		-e '/export KEY_EXPIRE=/d' \
		-e '/export KEY_COUNTRY=/d' \
		-e '/export KEY_PROVINCE=/d' \
		-e '/export KEY_CITY=/d' \
		-e '/export KEY_ORG=/d' \
		-e '/export KEY_OU=/d' vars
cat <<EOF >> vars
export PKCS11_MODULE_PATH="$FORM_PKCS11_PIN"
export PKCS11_PIN="$FORM_PKCS11_PIN"
export KEY_SIZE="$FORM_KEY_SIZE"
export CA_EXPIRE="$FORM_SSL_Guarantee"
export KEY_EXPIRE="$FORM_SSL_Guarantee"
export KEY_COUNTRY="$FORM_SSL_C"
export KEY_PROVINCE="$FORM_SSL_ST"
export KEY_CITY="$FORM_SSL_L"
export KEY_ORG="$FORM_SSL_O"
export KEY_OU="$FORM_SSL_OU"
EOF
. ./vars
export KEY_EMAIL=$FORM_KEY_EMAIL
rm -f /etc/openvpn/easy-rsa/keys/{ca.crt,ca.csr,ca.key,server.crt,server.csr,server.key,index.txt}
touch ./keys/index.txt
./pkitool --batch --initca >/dev/null 2>&1
./pkitool --batch --server server >/dev/null 2>&1
./build-dh >/dev/null 2>&1 &
(echo "Edit Success" | main.sbin output_json 0) || exit 0
else
export KEY_EXPIRE=$FORM_SSL_Guarantee
export KEY_COUNTRY=$FORM_SSL_C
export KEY_PROVINCE=$FORM_SSL_ST
export KEY_CITY=$FORM_SSL_L
export KEY_ORG=$FORM_SSL_O
export KEY_OU=$FORM_SSL_OU
export KEY_CN=$FORM_SSL_CN
export KEY_EMAIL=$FORM_KEY_EMAIL
rm -f /etc/openvpn/easy-rsa/keys/{$tar_get.crt,$tar_get.csr,$tar_get.key}
./pkitool $1 >/dev/null 2>&1
(echo "Edit Success" | main.sbin output_json 0) || exit 0
fi
}
build()
{
tar_get=`echo $FORM_file | sed 's/\.crt$//'`
do_crt $tar_get || (echo "Fail" | main.sbin output_json 1) || exit 1

}
build_new()
{
[ "$FORM_SSL_CN" = "`echo "$FORM_SSL_CN" | grep -Po "[a-zA-Z0-9-_]*"`" ] || (echo "CN Fail" | main.sbin output_json 1) || exit 1
do_crt $FORM_SSL_CN || (echo "Fail" | main.sbin output_json 1) || exit 1

}
save_openvpn_conf()
{
echo "$FORM_openvpn_conf_str" > /etc/openvpn/openvpn.conf
(echo "Success" | main.sbin output_json 0) || exit 0
}
del_ssl()
{
tar_get=`echo $FORM_crt_file | sed 's/\.crt$//'`

rm -f /etc/openvpn/easy-rsa/keys/$tar_get.crt
rm -f /etc/openvpn/easy-rsa/keys/$tar_get.csr
rm -f /etc/openvpn/easy-rsa/keys/$tar_get.key

(echo "Success" | main.sbin output_json 0) || exit 0
}
download()
{
tar_get=`echo $FORM_crt_file | sed 's/\.crt$//'`
rm -rf /tmp/openvpn_ssl
mkdir /tmp/openvpn_ssl
cp /etc/openvpn/easy-rsa/keys/{ca.crt,dh1024.pem,$tar_get.crt,$tar_get.key} /tmp/openvpn_ssl
cat <<EOF > /tmp/openvpn_ssl/$tar_get.ovpn
client
tls-client
dev tun
proto udp
remote $SERVER_NAME 1194 # Change to your router's External IP
resolv-retry infinite
nobind
ca ca.crt
cert client.crt
key client.key
dh dh1024.pem
#comp-lzo

persist-tun
persist-key
verb 3
EOF
cd /tmp
tar czf openvpn_ssl.tar.gz openvpn_ssl
main.sbin http_download /tmp/openvpn_ssl.tar.gz "openvpn_ssl_"$tar_get.tar.gz
}
wan_dest()
{
dest=`env | grep "^FORM_wan_zone_" | awk -F "=" {'print $2'} | tr '\n' ' '`
sed -i '/^dest_wan=/d' $DOCUMENT_ROOT/apps/openvpn/openvpn_extra.conf
echo "dest_wan=\"$dest\"" >> $DOCUMENT_ROOT/apps/openvpn/openvpn_extra.conf
(echo "Success" | main.sbin output_json 0) || exit 0
}
base_setting()
{
config_str=`cat /etc/openvpn/openvpn.conf`
[ -n "$FORM_port" ] && config_str=`echo "$config_str" | sed "s/^port[ ]*.*/port $FORM_port/" `
[ -n "$FORM_proto" ] && config_str=`echo "$config_str" | sed "s/^proto[ ]*.*/proto $FORM_proto/"`
[ -n "$FORM_server_ip" ] && [ -n "$FORM_server_mask" ] && config_str=`echo "$config_str" | sed "s/^server[ ]*.*/server $FORM_server_ip $FORM_server_mask/"`
[ -n "$config_str" ] && echo "$config_str" > /etc/openvpn/openvpn.conf
sed -i '/push \"dhcp-option DNS /d' /etc/openvpn/openvpn.conf
[ -n "$FORM_dns1" ] && echo "push \"dhcp-option DNS $FORM_dns1\"" >> /etc/openvpn/openvpn.conf
[ -n "$FORM_dns2" ] && echo "push \"dhcp-option DNS $FORM_dns2\"" >> /etc/openvpn/openvpn.conf

(echo "Success" | main.sbin output_json 0) || exit 0
}

openvpn_service()
{
if
[ "$FORM_openvpn_enable" = "1" ]
then
sed -i "s/^enable=.*/enable=$FORM_openvpn_enable/g" $DOCUMENT_ROOT/apps/openvpn/S901openvpn.init
$DOCUMENT_ROOT/apps/openvpn/S901openvpn.init start
main.sbin notice option="add" \
				read="0" \
				desc="_NOTICE_openvpn_service_enable" \
				detail="_NOTICE_openvpn_service_enable" \
				uniqid="" \
				time="" \
				ergen="green" \
				dest="openvpn" \
				dest_type="app" >/dev/null 2>&1
(echo "Success turn on" | main.sbin output_json 0) || exit 0
else
sed -i "s/^enable=.*/enable=$FORM_openvpn_enable/g" $DOCUMENT_ROOT/apps/openvpn/S901openvpn.init
$DOCUMENT_ROOT/apps/openvpn/S901openvpn.init stop
service openvpn stop >/dev/null 2>&1
main.sbin notice option="add" \
				read="0" \
				desc="_NOTICE_openvpn_service_disable" \
				detail="_NOTICE_openvpn_service_disable" \
				uniqid="" \
				time="" \
				ergen="red" \
				dest="openvpn" \
				dest_type="app" >/dev/null 2>&1
(echo "Success turn off" | main.sbin output_json 0) || exit 0
fi
}

. $DOCUMENT_ROOT/apps/sysinfo/sysinfo_lib.sh

