#!/bin/sh

main()
{
[ "`md5sum $DOCUMENT_ROOT/../sources/phpsysinfo-3.1.17.tar.gz | awk {'print $1'}`" = "4390fd8115496514490ef40b2e375b09" ]
[ $? -eq 0 ] || warning

cat <<'EOF'
<script>
$(function(){
  $('#phpsysinfo_setting').on('submit', function(e){
    e.preventDefault();
    var data = "app=phpsysinfo&"+$(this).serialize();
    var url = 'index.cgi';
    Ha.common.ajax(url, 'json', data, 'post', 'ajax-proxy');
	setTimeout("window.location.reload();", 2000);
  });
});
</script>
EOF
nginx_vhost_str=`cat $DOCUMENT_ROOT/apps/nginx/nginx_vhost.json`
nginx_port=`echo "$nginx_vhost_str" | jq -r '.["default"]["listen"]["port"]'`
config_str=`cat $DOCUMENT_ROOT/apps/phpsysinfo/phpsysinfo.conf`
phpsysinfo_dir=`echo "$config_str" | jq -r '.["phpsysinfo"]["phpsysinfo_dir"]'`
phpsysinfo_php_enable=`echo "$config_str" | jq -r '.["phpsysinfo"]["phpsysinfo_php_enable"]'`

cat <<EOF
<div class="col-md-8">
<legend>phpsysinfo  manage</legend>
<form id="phpsysinfo_setting">
<table class="table">
	<tr>
		<td>
		<a target="_blank" href="http://$SERVER_NAME:$nginx_port/$(echo "$config_str" | jq -r '.["phpsysinfo"]["phpsysinfo_dir"]' | sed -e 's#/data/htdocs/www/##' -e 's#/$##')/">phpsysinfo</a>
		</td>
		<td>
		<input type="text" class="form-control" name="phpsysinfo_dir" placeholder="/data/htdocs/www/phpsysinfo/" value="`([ -n "$phpsysinfo_dir" ] && [ "$phpsysinfo_dir" != "null" ] ) && echo "$phpsysinfo_dir" || echo "/data/htdocs/www/phpsysinfo/"`">
		</td>
		<td>
		<select name="phpsysinfo_php_enable">
		  <option value="0" `[ $phpsysinfo_php_enable -eq 0 ] && echo "selected=\"selected\""`>Off</option>
		  <option value="1" `[ $phpsysinfo_php_enable -eq 1 ] && echo "selected=\"selected\""`>On</option>
		</select>
		</td>
	</tr>
	<tr>
		<td>
		Option
		</td>
		<td>
		<input type="hidden" name="action" value="phpsysinfo_setting">
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
phpsysinfo_setting()
{
[ $FORM_phpsysinfo_php_enable -eq 0 ] || (ls -a $FORM_phpsysinfo_dir | grep -qP '[\w]' && exit 1 || exit 0) || (echo "There has some file." | main.sbin output_json 1) || exit 1

config_str=`cat $DOCUMENT_ROOT/apps/phpsysinfo/phpsysinfo.conf`
old_phpsysinfo_dir=$(echo "$config_str" | jq -r '.["phpsysinfo"]["phpsysinfo_dir"]')
rm -rf $old_phpsysinfo_dir
config_str=`echo "$config_str" | jq '.["phpsysinfo"]["phpsysinfo_dir"] = "'"$FORM_phpsysinfo_dir"'"'`
config_str=`echo "$config_str" | jq '.["phpsysinfo"]["phpsysinfo_php_enable"] = "'"$FORM_phpsysinfo_php_enable"'"'`
if
echo "$config_str" | jq '.' | grep -q "{"
then
echo "$config_str" >$DOCUMENT_ROOT/apps/phpsysinfo/phpsysinfo.conf
new_phpsysinfo_dir=$(echo "$config_str" | jq -r '.["phpsysinfo"]["phpsysinfo_dir"]')
if
[ `echo "$config_str" | jq -r '.["phpsysinfo"]["phpsysinfo_php_enable"]'` -eq 1 ]
then
	mkdir -p $new_phpsysinfo_dir
	rm -rf $DOCUMENT_ROOT/../tmp/phpsysinfo-3.1.17/
	tar zxf $DOCUMENT_ROOT/../sources/phpsysinfo-3.1.17.tar.gz -C $DOCUMENT_ROOT/../tmp
	mv $DOCUMENT_ROOT/../tmp/phpsysinfo-3.1.17/* $new_phpsysinfo_dir
	cp $new_phpsysinfo_dir"/phpsysinfo.ini.new" $new_phpsysinfo_dir"/phpsysinfo.ini"
	rm -rf $DOCUMENT_ROOT/../tmp/phpsysinfo-3.1.17/
fi
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
pre_install_phpsysinfo()
{
check_php_nginx_instaed || (echo "Please install php and nginx first" && exit 1) || exit 1
echo "Do you want to continue to download the source?"
}
download_phpsysinfo()
{
export download_json='{
"file_name":"phpsysinfo-3.1.17.tar.gz",
"downloader":"aria2 curl wget",
"save_dest":"$DOCUMENT_ROOT/../sources/phpsysinfo-3.1.17.tar.gz",
"useragent":"Mozilla/4.0 (compatible; MSIE 6.1; Windows XP)",
"timeout":20,
"md5sum":"4390fd8115496514490ef40b2e375b09",
	"download_urls":{
	"github":"http://www.mirrorservice.org/sites/dl.sourceforge.net/pub/sourceforge/p/ph/phpsysinfo/phpsysinfo/3.1.17/phpsysinfo-3.1.17.tar.gz",
	"github":"http://jaist.dl.sourceforge.net/project/phpsysinfo/phpsysinfo/3.1.17/phpsysinfo-3.1.17.tar.gz"
	}
}'
main.sbin download
}
install_phpsysinfo()
{
check_php_nginx_instaed || (echo "Please install php and nginx first" && exit 1) || exit 1
download_phpsysinfo
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
        <h4 class="modal-title">$_LANG_Download_phpsysinfo</h4>
      </div>
      <div class="modal-body" style="overflow-y: auto;height: 480px;">
		<p id="fix_content"></p>
      </div>
      <div class="modal-footer">
        <button type="button" onclick="javascript:history.go(0)" class="btn btn-default" data-dismiss="modal">$_LANG_Close</button>
		<input type="hidden" name="action">
        <button type="button" href="javascript:;" class="btn btn-info" id="install_phpsysinfo" data-loading-text="Loading...">$_LANG_Install_or_View_Progress</button>
      </div>
    </div>
  </div>
</div>

	<div class="col-md-10">
	<p class="bg-danger">$_LANG_phpsysinfo_need_Download<p>
	</div>
	<div class="col-md-2">
<a class="btn btn-info" href="javascript:;" id="fixer">$_LANG_Fixer</a>
	</div>
</div>
EOF
cat <<'EOF'
<script>
$('#fixer').on('click', function(){
	var url = 'index.cgi?app=phpsysinfo&action=pre_install_phpsysinfo';
	Ha.common.ajax(url, 'html', '', 'get', 'applist', function(data){
		$('#fix_content').html(data);
		$('#fix_Modal').modal('show');
	}, 1);
});

function do_install_phpsysinfo()
{
var url = 'index.cgi?app=phpsysinfo&action=install_phpsysinfo';
	Ha.common.ajax(url, 'html', '', 'get', 'applist', function(data){
		$('#fix_content').html(data);
		$('#fix_Modal').modal('show');
	}, 1);
}
$('#install_phpsysinfo').on('click', function(){
var $btn = $(this);
    $btn.button('loading');

	setInterval("do_install_phpsysinfo()", 5000);

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