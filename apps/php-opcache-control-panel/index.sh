#!/bin/sh

main()
{
tar tvzf $DOCUMENT_ROOT/../sources/opcache-gui-2.0.0.tar.gz | grep -q "/index.php" && \
unzip -vx $DOCUMENT_ROOT/../sources/opcache-status.zip | grep -qE "/opcache.php" 
[ $? -eq 0 ] || warning
cat <<'EOF'
<script>
$(function(){
  $('#opcache_control_panel_setting').on('submit', function(e){
    e.preventDefault();
    var data = "app=php-opcache-control-panel&"+$(this).serialize();
    var url = 'index.cgi';
    Ha.common.ajax(url, 'json', data, 'post', 'ajax-proxy');
	setTimeout("window.location.reload();", 2000);
  });
});
</script>
EOF
nginx_vhost_str=`cat $DOCUMENT_ROOT/apps/nginx/nginx_vhost.json`
nginx_port=`echo "$nginx_vhost_str" | jq -r '.["default"]["listen"]["port"]'`
config_str=`cat $DOCUMENT_ROOT/apps/php-opcache-control-panel/php_opcache_control_panel.conf`
opcache_status_dir=`echo "$config_str" | jq -r '.["opcache_status"]["opcache_status_dir"]'`
opcache_gui_dir=`echo "$config_str" | jq -r '.["opcache_gui"]["opcache_gui_dir"]'`
opcache_control_panel_dir=`echo "$config_str" | jq -r '.["opcache_control_panel"]["opcache_control_panel_dir"]'`
opcache_status_enable=`echo "$config_str" | jq -r '.["opcache_status"]["opcache_status_enable"]'`
opcache_gui_enable=`echo "$config_str" | jq -r '.["opcache_gui"]["opcache_gui_enable"]'`
opcache_control_panel_enable=`echo "$config_str" | jq -r '.["opcache_control_panel"]["opcache_control_panel_enable"]'`

cat <<EOF
<div class="col-md-8">
<legend>opcache-control-panel manage</legend>
<form id="opcache_control_panel_setting">
<table class="table">
	<tr>
		<td>
		<a target="_blank" href="http://$SERVER_NAME:$nginx_port/$(echo "$config_str" | jq -r '.["opcache_status"]["opcache_status_dir"]' | sed -e 's#/data/htdocs/www/##' -e 's#/$##')/">opcache-status</a>
		</td>
		<td>
		<input type="text" class="form-control" name="opcache_status_dir" placeholder="/data/htdocs/www/opcache_control_panel/" value="`([ -n "$opcache_status_dir" ] && [ "$opcache_status_dir" != "null" ] ) && echo "$opcache_status_dir" || echo "/data/htdocs/www/opcache-status/"`">
		</td>
		<td>
		<select name="opcache_status_enable">
		  <option value="0" `[ $opcache_status_enable -eq 0 ] && echo "selected=\"selected\""`>Off</option>
		  <option value="1" `[ $opcache_status_enable -eq 1 ] && echo "selected=\"selected\""`>On</option>
		</select>
		</td>
	</tr>
	<tr>
		<td>
		<a target="_blank" href="http://$SERVER_NAME:$nginx_port/$(echo "$config_str" | jq -r '.["opcache_gui"]["opcache_gui_dir"]' | sed -e 's#/data/htdocs/www/##' -e 's#/$##')/">opcache-gui</a>
		</td>
		<td>
		<input type="text" class="form-control" name="opcache_gui_dir" placeholder="/data/htdocs/www/opcache_control_panel/" value="`([ -n "$opcache_gui_dir" ] && [ "$opcache_gui_dir" != "null" ] ) && echo "$opcache_gui_dir" || echo "/data/htdocs/www/opcache-gui/"`">
		</td>
		<td>
		<select name="opcache_gui_enable">
		  <option value="0" `[ $opcache_gui_enable -eq 0 ] && echo "selected=\"selected\""`>Off</option>
		  <option value="1" `[ $opcache_gui_enable -eq 1 ] && echo "selected=\"selected\""`>On</option>
		</select>
		</td>
	</tr>
	<tr>
		<td>
		<a target="_blank" href="http://$SERVER_NAME:$nginx_port/$(echo "$config_str" | jq -r '.["opcache_control_panel"]["opcache_control_panel_dir"]' | sed -e 's#/data/htdocs/www/##' -e 's#/$##')/ocp.php">ocp.php</a>
		</td>
		<td>
		<input type="text" class="form-control" name="opcache_control_panel_dir" placeholder="/data/htdocs/www/opcache_control_panel/" value="`([ -n "$opcache_control_panel_dir" ] && [ "$opcache_control_panel_dir" != "null" ] ) && echo "$opcache_control_panel_dir" || echo "/data/htdocs/www/opcache-control-panel/"`">
		</td>
		<td>
		<select name="opcache_control_panel_enable">
		  <option value="0" `[ $opcache_control_panel_enable -eq 0 ] && echo "selected=\"selected\""`>Off</option>
		  <option value="1" `[ $opcache_control_panel_enable -eq 1 ] && echo "selected=\"selected\""`>On</option>
		</select>
		</td>
	</tr>
	<tr>
		<td>
		Option
		</td>
		<td>
		<input type="hidden" name="action" value="opcache_control_panel_setting">
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
opcache_control_panel_setting()
{
config_str=`cat $DOCUMENT_ROOT/apps/php-opcache-control-panel/php_opcache_control_panel.conf`
old_opcache_status_dir=$(echo "$config_str" | jq -r '.["opcache_status"]["opcache_status_dir"]')
old_opcache_gui_dir=$(echo "$config_str" | jq -r '.["opcache_gui"]["opcache_gui_dir"]')
old_opcache_control_panel_dir=$(echo "$config_str" | jq -r '.["opcache_control_panel"]["opcache_control_panel_dir"]')
old_opcache_status_file="$old_opcache_status_dir""/opcache-status"
old_opcache_gui_file="$old_opcache_gui_dir""/opcache-gui"
old_opcache_control_panel_file="$old_opcache_control_panel_dir""/opcache_control_panel.php"
rm -f $old_opcache_status_file
rm -f $old_opcache_gui_file
rm -f $old_opcache_control_panel_file
ls -a $old_opcache_status_dir | grep -qE "[\w]" || rm -rf $old_opcache_status_dir
ls -a $old_opcache_gui_dir | grep -qE "[\w]" || rm -rf $old_opcache_gui_dir
ls -a $old_opcache_control_panel_dir | grep -qE "[\w]" || rm -rf $old_opcache_control_panel_dir
config_str=`echo "$config_str" | jq '.["opcache_status"]["opcache_status_dir"] = "'"$FORM_opcache_status_dir"'"'`
config_str=`echo "$config_str" | jq '.["opcache_gui"]["opcache_gui_dir"] = "'"$FORM_opcache_gui_dir"'"'`
config_str=`echo "$config_str" | jq '.["opcache_control_panel"]["opcache_control_panel_dir"] = "'"$FORM_opcache_control_panel_dir"'"'`
config_str=`echo "$config_str" | jq '.["opcache_status"]["opcache_status_enable"] = "'"$FORM_opcache_status_enable"'"'`
config_str=`echo "$config_str" | jq '.["opcache_gui"]["opcache_gui_enable"] = "'"$FORM_opcache_gui_enable"'"'`
config_str=`echo "$config_str" | jq '.["opcache_control_panel"]["opcache_control_panel_enable"] = "'"$FORM_opcache_control_panel_enable"'"'`
if
echo "$config_str" | jq '.' | grep -q "{"
then
echo "$config_str" >$DOCUMENT_ROOT/apps/php-opcache-control-panel/php_opcache_control_panel.conf
config_str=`cat $DOCUMENT_ROOT/apps/php-opcache-control-panel/php_opcache_control_panel.conf`
new_opcache_status_dir=$(echo "$config_str" | jq -r '.["opcache_status"]["opcache_status_dir"]')
new_opcache_gui_dir=$(echo "$config_str" | jq -r '.["opcache_gui"]["opcache_gui_dir"]')
new_opcache_control_panel_dir=$(echo "$config_str" | jq -r '.["opcache_control_panel"]["opcache_control_panel_dir"]')
[ `echo "$config_str" | jq -r '.["opcache_status"]["opcache_status_enable"]'` -eq 1 ] && rm -rf $DOCUMENT_ROOT/../tmp/opcache-status-master $new_opcache_status_dir && unzip $DOCUMENT_ROOT/../sources/opcache-status.zip -d $DOCUMENT_ROOT/../tmp && mv $DOCUMENT_ROOT/../tmp/opcache-status-master $new_opcache_status_dir && cd $new_opcache_status_dir && mv opcache.php index.php 
[ `echo "$config_str" | jq -r '.["opcache_gui"]["opcache_gui_enable"]'` -eq 1 ] && rm -rf $DOCUMENT_ROOT/../tmp/opcache-gui-2.0.0 $new_opcache_gui_dir && tar zxf $DOCUMENT_ROOT/../sources/opcache-gui-2.0.0.tar.gz -C $DOCUMENT_ROOT/../tmp/ && mv $DOCUMENT_ROOT/../tmp/opcache-gui-2.0.0 $new_opcache_gui_dir
[ `echo "$config_str" | jq -r '.["opcache_control_panel"]["opcache_control_panel_enable"]'` -eq 1 ] && mkdir -p $new_opcache_control_panel_dir && cp $DOCUMENT_ROOT/apps/php-opcache-control-panel/files/ocp.php.file $new_opcache_control_panel_dir/ocp.php
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
pre_install_opcache_control_panel()
{
check_php_nginx_instaed || (echo "Please install php and nginx first" && exit 1) || exit 1
echo "Do you want to continue to download the source?"
}
download_opcache_control_panel()
{
export download_json='{
"file_name":"opcache-gui-2.0.0.tar.gz",
"downloader":"aria2 curl wget",
"save_dest":"$DOCUMENT_ROOT/../sources/opcache-gui-2.0.0.tar.gz",
"useragent":"Mozilla/4.0 (compatible; MSIE 6.1; Windows XP)",
"timeout":20,
"md5sum":"ec750e2d43d8f3b25f37b0a116e470be",
	"download_urls":{
	"github":"https://github.com/amnuts/opcache-gui/archive/v2.0.0.tar.gz"
	}
}'
main.sbin download
export download_json='{
"file_name":"opcache-status.zip",
"downloader":"aria2 curl wget",
"save_dest":"$DOCUMENT_ROOT/../sources/opcache-status.zip",
"useragent":"Mozilla/4.0 (compatible; MSIE 6.1; Windows XP)",
"timeout":20,
"md5sum":"indefinite",
	"download_urls":{
	"github":"https://github.com/rlerdorf/opcache-status/archive/master.zip"
	}
}'
main.sbin download
}
install_opcache_control_panel()
{
check_php_nginx_instaed || (echo "Please install php and nginx first" && exit 1) || exit 1
download_opcache_control_panel
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
        <h4 class="modal-title">$_LANG_Download_php_opcache_control_panel</h4>
      </div>
      <div class="modal-body" style="overflow-y: auto;height: 480px;">
		<p id="fix_content"></p>
      </div>
      <div class="modal-footer">
        <button type="button" onclick="javascript:history.go(0)" class="btn btn-default" data-dismiss="modal">$_LANG_Close</button>
		<input type="hidden" name="action">
        <button type="button" href="javascript:;" class="btn btn-info" id="install_opcache_control_panel" data-loading-text="Loading...">$_LANG_Install_or_View_Progress</button>
      </div>
    </div>
  </div>
</div>

	<div class="col-md-10">
	<p class="bg-danger">$_LANG_php_opcache_control_panel_need_Download<p>
	</div>
	<div class="col-md-2">
<a class="btn btn-info" href="javascript:;" id="fixer">$_LANG_Fixer</a>
	</div>
</div>
EOF
cat <<'EOF'
<script>
$('#fixer').on('click', function(){
	var url = 'index.cgi?app=php-opcache-control-panel&action=pre_install_opcache_control_panel';
	Ha.common.ajax(url, 'html', '', 'get', 'applist', function(data){
		$('#fix_content').html(data);
		$('#fix_Modal').modal('show');
	}, 1);
});

function do_install_opcache_control_panel()
{
var url = 'index.cgi?app=php-opcache-control-panel&action=install_opcache_control_panel';
	Ha.common.ajax(url, 'html', '', 'get', 'applist', function(data){
		$('#fix_content').html(data);
		$('#fix_Modal').modal('show');
	}, 1);
}
$('#install_opcache_control_panel').on('click', function(){
var $btn = $(this);
    $btn.button('loading');

	setInterval("do_install_opcache_control_panel()", 5000);

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