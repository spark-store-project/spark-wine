#/bin/bash
DEPEND=`dpkg -l | grep   fakeroot`
if [ "$DEPEND" = "" ] ; then 
echo "未安装依赖：fakeroot 本脚本退出"
exit 1
fi

if [ $# -lt 1 ]; then
echo "无参数，无法启动。用法 $0 版本号"
echo "No option detected, exit. Usage: $0 version"
exit 1
fi

version="$1"
######################################################
echo "build debian package"
mkdir -p  pkg/DEBIAN
cp -r ./s-wine-helper pkg/opt
SIZE=`du -s ./pkg`
SIZE=`echo ${SIZE%%.*}`

cat  << EOF >pkg/DEBIAN/control
Package: spark-dwine-helper
Version: $version
Architecture: all
Maintainer: shenmo <shenmo@spark-app.store>
Installed-Size: $SIZE
Depends: zenity:amd64, p7zip-full:amd64, fonts-noto-cjk,deepin-wine-helper(>=5.1),transhell
Section: utils
Priority: extra
Recommends: spark-dwine-helper-settings
Multi-Arch: foreign
Provides: store.spark-app.spark-dwine-helper(=$version)
Replaces: store.spark-app.spark-dwine-helper(<=$version)
Homepage: https://gitee.com/deepin-community-store/spark-wine
Description: Spark Deepin Wine Helper


EOF

cp postrm pkg/DEBIAN/postrm


chmod +x pkg/DEBIAN/postrm

cd pkg && fakeroot dpkg-deb -Z xz -b . ../
cd ..

echo "普通deb包已经准备好，正在生成UOS deb包"
rm -rf pkg/
#################################################################
mkdir -p pkg/DEBIAN
cp -r uos-package-assets/opt pkg/
cp -r s-wine-helper/* pkg/opt

cat  << EOF >pkg/opt/apps/store.spark-app.spark-dwine-helper/info
{
    "appid": "store.spark-app.spark-dwine-helper",
    "name": "store.spark-app.spark-dwine-helper",
    "version": "$version",
    "arch": ["amd64,arm64,mipsel64,sw64"],
    "permissions": {
        "autostart": false,
        "notification": false,
        "trayicon": false,
        "clipboard": false,
        "account": false,
        "bluetooth": false,
        "camera": false,
        "audio_record": false,
        "installed_apps": false
    }
}



EOF

SIZE=`du -s ./pkg`
SIZE=`echo ${SIZE%%.*}`

cat  << EOF >pkg/DEBIAN/control
Package: store.spark-app.spark-dwine-helper
Version: $version
Architecture: all
Maintainer: shenmo <shenmo@spark-app.store>
Installed-Size: $SIZE
Depends: zenity:amd64, p7zip-full:amd64, fonts-noto-cjk,deepin-wine-helper(>=5.1),transhell
Section: utils
Priority: extra
Recommends: spark-dwine-helper-settings
Provides: spark-dwine-helper(=$version)
Conflicts: spark-dwine-helper
Replaces: spark-dwine-helper(<=$version)
Multi-Arch: foreign
Homepage: https://gitee.com/deepin-community-store/spark-wine
Description: Spark Deepin Wine Helper



EOF
cd pkg && fakeroot dpkg-deb -Z xz -b . ../
cd ..

echo "UOS deb包已经准备好"
rm -rf pkg/
########################################
mkdir -p pkg/DEBIAN
cp -r spark-dwine-helper-settings/* pkg/
SIZE=`du -s ./pkg`
SIZE=`echo ${SIZE%%.*}`

cat  << EOF >pkg/DEBIAN/control
Package: spark-dwine-helper-settings
Version: 1.3
Architecture: all
Maintainer: shenmo <shenmo@spark-app.store>
Installed-Size: $SIZE
Depends: spark-dwine-helper(>=1.6),transhell
Section: utils
Priority: extra
Multi-Arch: foreign
Homepage: https://gitee.com/deepin-community-store/spark-wine
Description: Spark Deepin Wine Helper



EOF

cd pkg && fakeroot dpkg-deb -Z xz -b . ../
cd ..

echo "helper deb包已经准备好"
rm -rf pkg/
