#!/bin/sh

main()
{
unzip -vx $DOCUMENT_ROOT/../sources/tz_e.zip | grep -qE "[ ]*tz_e.php" && \
unzip -vx $DOCUMENT_ROOT/../sources/tz_tw.zip | grep -qE "[ ]*tz_tw.php" && \
unzip -vx $DOCUMENT_ROOT/../sources/tz.zip | grep -qE "[ ]*tz.php"
[ $? -eq 0 ] || warning
cat <<'EOF'
<script>
$(function(){
  $('#tz_setting').on('submit', function(e){
    e.preventDefault();
    var data = "app=php-tz&"+$(this).serialize();
    var url = 'index.cgi';
    Ha.common.ajax(url, 'json', data, 'post', 'ajax-proxy');
	setTimeout("window.location.reload();", 2000);
  });
});
</script>
EOF
nginx_vhost_str=`cat $DOCUMENT_ROOT/apps/nginx/nginx_vhost.json`
nginx_port=`echo "$nginx_vhost_str" | jq -r '.["default"]["listen"]["port"]'`
config_str=`cat $DOCUMENT_ROOT/apps/php-tz/php_tz.conf`
tz_e_dir=`echo "$config_str" | jq -r '.["tz_e"]["tz_e_dir"]'`
tz_tw_dir=`echo "$config_str" | jq -r '.["tz_tw"]["tz_tw_dir"]'`
tz_dir=`echo "$config_str" | jq -r '.["tz"]["tz_dir"]'`
tz_e_php_enable=`echo "$config_str" | jq -r '.["tz_e"]["tz_e_php_enable"]'`
tz_tw_php_enable=`echo "$config_str" | jq -r '.["tz_tw"]["tz_tw_php_enable"]'`
tz_php_enable=`echo "$config_str" | jq -r '.["tz"]["tz_php_enable"]'`

cat <<EOF
<div class="col-md-8">
<legend>tz*.php manage</legend>
<form id="tz_setting">
<table class="table">
	<tr>
		<td>
		<a target="_blank" href="http://$SERVER_NAME:$nginx_port/$(echo "$config_str" | jq -r '.["tz_e"]["tz_e_dir"]' | sed -e 's#/data/htdocs/www/##' -e 's#/$##')/tz_e.php">tz_e.php</a>[English]
		</td>
		<td>
		<input type="text" class="form-control" name="tz_e_dir" placeholder="/data/htdocs/www/tz/" value="`([ -n "$tz_e_dir" ] && [ "$tz_e_dir" != "null" ] ) && echo "$tz_e_dir" || echo "/data/htdocs/www/tz/"`">
		</td>
		<td>
		<select name="tz_e_php_enable">
		  <option value="0" `[ $tz_e_php_enable -eq 0 ] && echo "selected=\"selected\""`>Off</option>
		  <option value="1" `[ $tz_e_php_enable -eq 1 ] && echo "selected=\"selected\""`>On</option>
		</select>
		</td>
	</tr>
	<tr>
		<td>
		<a target="_blank" href="http://$SERVER_NAME:$nginx_port/$(echo "$config_str" | jq -r '.["tz_tw"]["tz_tw_dir"]' | sed -e 's#/data/htdocs/www/##' -e 's#/$##')/tz_tw.php">tz_tw.php</a>[繁體中文]
		</td>
		<td>
		<input type="text" class="form-control" name="tz_tw_dir" placeholder="/data/htdocs/www/tz/" value="`([ -n "$tz_tw_dir" ] && [ "$tz_tw_dir" != "null" ] ) && echo "$tz_tw_dir" || echo "/data/htdocs/www/tz/"`">
		</td>
		<td>
		<select name="tz_tw_php_enable">
		  <option value="0" `[ $tz_tw_php_enable -eq 0 ] && echo "selected=\"selected\""`>Off</option>
		  <option value="1" `[ $tz_tw_php_enable -eq 1 ] && echo "selected=\"selected\""`>On</option>
		</select>
		</td>
	</tr>
	<tr>
		<td>
		<a target="_blank" href="http://$SERVER_NAME:$nginx_port/$(echo "$config_str" | jq -r '.["tz"]["tz_dir"]' | sed -e 's#/data/htdocs/www/##' -e 's#/$##')/tz.php">tz.php</a>[简体中文]
		</td>
		<td>
		<input type="text" class="form-control" name="tz_dir" placeholder="/data/htdocs/www/tz/" value="`([ -n "$tz_dir" ] && [ "$tz_dir" != "null" ] ) && echo "$tz_dir" || echo "/data/htdocs/www/tz/"`">
		</td>
		<td>
		<select name="tz_php_enable">
		  <option value="0" `[ $tz_php_enable -eq 0 ] && echo "selected=\"selected\""`>Off</option>
		  <option value="1" `[ $tz_php_enable -eq 1 ] && echo "selected=\"selected\""`>On</option>
		</select>
		</td>
	</tr>
	<tr>
		<td>
		Option
		</td>
		<td>
		<input type="hidden" name="action" value="tz_setting">
		<button class="btn btn-primary" id="_submit" type="submit">Save</button>
		</td>
	</tr>
</table>
</form>
</div>
<div class="col-md-4">

</div>
EOF

}
tz_setting()
{
config_str=`cat $DOCUMENT_ROOT/apps/php-tz/php_tz.conf`
old_tz_e_dir=$(echo "$config_str" | jq -r '.["tz_e"]["tz_e_dir"]')
old_tz_tw_dir=$(echo "$config_str" | jq -r '.["tz_tw"]["tz_tw_dir"]')
old_tz_dir=$(echo "$config_str" | jq -r '.["tz"]["tz_dir"]')
old_tz_e_file="$old_tz_e_dir""/tz_e.php"
old_tz_tw_file="$old_tz_tw_dir""/tz_tw.php"
old_tz_file="$old_tz_dir""/tz.php"
rm -f $old_tz_e_file
rm -f $old_tz_tw_file
rm -f $old_tz_file
ls -a $old_tz_e_dir | grep -qE "[\w]" || rm -rf $old_tz_e_dir
ls -a $old_tz_tw_dir | grep -qE "[\w]" || rm -rf $old_tz_tw_dir
ls -a $old_tz_dir | grep -qE "[\w]" || rm -rf $old_tz_dir
config_str=`echo "$config_str" | jq '.["tz_e"]["tz_e_dir"] = "'"$FORM_tz_e_dir"'"'`
config_str=`echo "$config_str" | jq '.["tz_tw"]["tz_tw_dir"] = "'"$FORM_tz_tw_dir"'"'`
config_str=`echo "$config_str" | jq '.["tz"]["tz_dir"] = "'"$FORM_tz_dir"'"'`
config_str=`echo "$config_str" | jq '.["tz_e"]["tz_e_php_enable"] = "'"$FORM_tz_e_php_enable"'"'`
config_str=`echo "$config_str" | jq '.["tz_tw"]["tz_tw_php_enable"] = "'"$FORM_tz_tw_php_enable"'"'`
config_str=`echo "$config_str" | jq '.["tz"]["tz_php_enable"] = "'"$FORM_tz_php_enable"'"'`
if
echo "$config_str" | jq '.' | grep -q "{"
then
echo "$config_str" >$DOCUMENT_ROOT/apps/php-tz/php_tz.conf
new_tz_e_dir=$(echo "$config_str" | jq -r '.["tz_e"]["tz_e_dir"]')
new_tz_tw_dir=$(echo "$config_str" | jq -r '.["tz_tw"]["tz_tw_dir"]')
new_tz_dir=$(echo "$config_str" | jq -r '.["tz"]["tz_dir"]')
[ `echo "$config_str" | jq -r '.["tz_e"]["tz_e_php_enable"]'` -eq 1 ] && mkdir -p $new_tz_e_dir && unzip $DOCUMENT_ROOT/../sources/tz_e.zip -d $new_tz_e_dir
[ `echo "$config_str" | jq -r '.["tz_tw"]["tz_tw_php_enable"]'` -eq 1 ] && mkdir -p $new_tz_tw_dir && unzip $DOCUMENT_ROOT/../sources/tz_tw.zip -d $new_tz_tw_dir
[ `echo "$config_str" | jq -r '.["tz"]["tz_php_enable"]'` -eq 1 ] && mkdir -p $new_tz_dir && unzip $DOCUMENT_ROOT/../sources/tz.zip -d $new_tz_dir
(echo "Save Success." | main.sbin output_json 0) || exit 0
else
(echo "Fail" | main.sbin output_json 1) || exit 1
fi
}
check_php_nginx_instaed()
{
if
[ ! -x /usr/local/php/bin/php ] && \
[ ! -x /usr/local/nginx/sbin/nginx ]
then
return 1
fi
}
pre_install_tz()
{
check_php_nginx_instaed || (echo "Please install php and nginx first" && exit 1) || exit 1
echo "Do you want to continue to download the source?"
}
download_tz()
{
export download_json='{
"file_name":"tz.zip",
"downloader":"aria2 curl wget",
"save_dest":"$DOCUMENT_ROOT/../sources/tz.zip",
"useragent":"Mozilla/4.0 (compatible; MSIE 6.1; Windows XP)",
"timeout":20,
"md5sum":"indefinite",
	"download_urls":{
	"github":"http://www.yahei.net/tz/tz.zip"
	}
}'
main.sbin download
export download_json='{
"file_name":"tz_tw.zip",
"downloader":"aria2 curl wget",
"save_dest":"$DOCUMENT_ROOT/../sources/tz_tw.zip",
"useragent":"Mozilla/4.0 (compatible; MSIE 6.1; Windows XP)",
"timeout":20,
"md5sum":"indefinite",
	"download_urls":{
	"github":"http://www.yahei.net/tz/tz_tw.zip"
	}
}'
main.sbin download
export download_json='{
"file_name":"tz_e.zip",
"downloader":"aria2 curl wget",
"save_dest":"$DOCUMENT_ROOT/../sources/tz_e.zip",
"useragent":"Mozilla/4.0 (compatible; MSIE 6.1; Windows XP)",
"timeout":20,
"md5sum":"indefinite",
	"download_urls":{
	"github":"http://www.yahei.net/tz/tz_e.zip"
	}
}'
main.sbin download
}
install_tz()
{
check_php_nginx_instaed || (echo "Please install php and nginx first" && exit 1) || exit 1
download_tz
echo "Download Success"
}
warning()
{
cat <<EOF
<div class="container">
<div class="modal fade" id="fix_Modal">
  <div class="modal-dialog modal-lg">
    <div class="modal-content">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
        <h4 class="modal-title">$_LANG_Download_php_tz</h4>
      </div>
      <div class="modal-body" style="overflow-y: auto;height: 480px;">
		<p id="fix_content"></p>
      </div>
      <div class="modal-footer">
        <button type="button" onclick="javascript:history.go(0)" class="btn btn-default" data-dismiss="modal">$_LANG_Close</button>
		<input type="hidden" name="action">
        <button type="button" href="javascript:;" class="btn btn-info" id="install_tz" data-loading-text="Loading...">$_LANG_Install_or_View_Progress</button>
      </div>
    </div>
  </div>
</div>

	<div class="col-md-10">
	<p class="bg-danger">$_LANG_php_tz_need_Download<p>
	</div>
	<div class="col-md-2">
<a class="btn btn-info" href="javascript:;" id="fixer">$_LANG_Fixer</a>
	</div>
</div>
EOF
cat <<'EOF'
<script>
$('#fixer').on('click', function(){
	var url = 'index.cgi?app=php-tz&action=pre_install_tz';
	Ha.common.ajax(url, 'html', '', 'get', 'applist', function(data){
		$('#fix_content').html(data);
		$('#fix_Modal').modal('show');
	}, 1);
});

function do_install_tz()
{
var url = 'index.cgi?app=php-tz&action=install_tz';
	Ha.common.ajax(url, 'html', '', 'get', 'applist', function(data){
		$('#fix_content').html(data);
		$('#fix_Modal').modal('show');
	}, 1);
}
$('#install_tz').on('click', function(){
var $btn = $(this);
    $btn.button('loading');

	setInterval("do_install_tz()", 5000);

});
</script>
EOF
}

lang=`main.sbin get_client_lang`
eval `cat $DOCUMENT_ROOT/apps/$FORM_app/i18n/$lang/i18n.conf`
. $DOCUMENT_ROOT/apps/sysinfo/sysinfo_lib.sh
if
[ $is_main_page = 1 ]
then
main
elif [ -n "$FORM_action" ]
then
$FORM_action
fi