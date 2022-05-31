#!/bin/bash

#   Copyright (C) 2016 Deepin, Inc.
#   Copyright (C) 2022 The Spark Project
#
#   Author:     Li LongYu <lilongyu@linuxdeepin.com>
#               Peng Hao <penghao@linuxdeepin.com>
#
#   Modifier:   shenmo <shenmo@spark-app.store>
#		   
#   diff: Now will run set-dwine-scale.sh in stage RunApp before CallApp
#         Deleted Deepin-* to simplify the script
#
WINEPREFIX="$HOME/.deepinwine/@public_bottle_name@"
APPDIR="/opt/deepinwine/apps/@public_bottle_name@"
APPVER="@deb_version_string@"
APPTAR="files.7z"
BOTTLENAME=""
WINE_CMD="deepin-wine"
#这里会被后续覆盖，似乎没啥用
LOG_FILE=$0
PUBLIC_DIR="/var/public"

SHELL_DIR=$(dirname $0)
SHELL_DIR=$(realpath "$SHELL_DIR")
if [ $SPECIFY_SHELL_DIR ]; then
    SHELL_DIR=$SPECIFY_SHELL_DIR
fi

if [ $APPRUN_CMD ]; then
    WINE_CMD=$APPRUN_CMD
fi

if [ $SPECIFY_SHELL_DIR ]; then
    SHELL_DIR=$SPECIFY_SHELL_DIR
fi

UsePublicDir()
{
    if [ -z "$USE_PUBLIC_DIR" ]; then
        echo "Don't use public dir"
        return 1
    fi
    if [ ! -d "$PUBLIC_DIR" ];then
        echo "Not found $PUBLIC_DIR"
        return 1
    fi
    if [ ! -r "$PUBLIC_DIR" ];then
        echo "Can't read for $PUBLIC_DIR"
        return 1
    fi
    if [ ! -w "$PUBLIC_DIR" ];then
        echo "Can't write for $PUBLIC_DIR"
        return 1
    fi
    if [ ! -x "$PUBLIC_DIR" ];then
        echo "Can't excute for $PUBLIC_DIR"
        return 1
    fi

    return 0
}
########关于公共文件夹，暂时意义不明

_DeleteRegistry()
{
    env WINEPREFIX="$WINEPREFIX" $WINE_CMD reg DELETE "$1" /f &> /dev/null
}
#########功能：删除注册表
init_log_file()
{
    if [ ! -d "$DEBUG_LOG" ];then
        return
    fi

    LOG_DIR=$(realpath $DEBUG_LOG)
    if [ -d "$LOG_DIR" ];then
        LOG_FILE="${LOG_DIR}/${LOG_FILE##*/}.log"
        echo "" > "$LOG_FILE"
        debug_log "LOG_FILE=$LOG_FILE"
    fi
}

debug_log_to_file()
{
    if [ -d "$DEBUG_LOG" ];then
        echo -e "${1}" >> "$LOG_FILE"
    fi
}

debug_log()
{
    echo "${1}"
}
################log相关功能
HelpApp()
{
	echo " Extra Commands:"
	echo " -r/--reset     Reset app to fix errors"
	echo " -e/--remove    Remove deployed app files"
	echo " -h/--help      Show program help info"
}
#############帮助文件
FixLink()
{
    if [ -d ${WINEPREFIX} ]; then
        CUR_DIR=$PWD
        cd "${WINEPREFIX}/dosdevices"
        rm c: z: y:
        ln -s -f ../drive_c c:
        ln -s -f / z:
        ln -s -f $HOME y:
        cd $CUR_DIR
        ls -l "${WINEPREFIX}/dosdevices"
    fi
}
###########会在应用启动和解压时执行，驱动器绑定
DisableWrite()
{
    if [ -d "${1}" ]; then
        chmod +w "${1}"
        rm -rf "${1}"
    fi

    mkdir "${1}"
    chmod -w "${1}"
}
########如果有该文件夹则删除，然后再创建一个不允许写入的（这东西是被用在了QQ启动上，看来腾讯不怎么好对付）
is_autostart()
{
    AUTOSTART="/opt/deepinwine/tools/autostart"
    if [ -f "$AUTOSTART.all" ]&&[ -f "/opt/apps/$1/files/run.sh" ];then
        return 0
    fi

    if [ -f $AUTOSTART ];then
        grep -c "$1" $AUTOSTART > /dev/null
        return $?
    fi

    return 1
}
#########自动启动相关，等用到了再研究
urldecode() { : "${*//+/ }"; echo -e "${_//%/\\x}"; }
#######url转义

#arg 1: windows process file path
#arg 2-*: windows process args
CallProcess()
{
    #get file full path
    path="$1"
    path=$(echo ${path/c:/${WINEPREFIX}/drive_c})
    path=$(echo ${path//\\/\/})

    #kill bloack process
    is_autostart $DEB_PACKAGE_NAME
    autostart=$?
    if [ $autostart -ne 0 ];then
        $SHELL_DIR/kill.sh "$BOTTLENAME" block
    fi

    #change current dir to excute path
    path=$(dirname "$path")
    cd "$path"
    pwd

    #Set default mime type
    if [ -n "$MIME_TYPE" ]; then
        xdg-mime default "$DEB_PACKAGE_NAME".desktop "$MIME_TYPE"
    fi

    debug_log_to_file "Starting process $* ..."

    env WINEPREFIX="$WINEPREFIX" $WINE_CMD "$@" &

    #start autobottle
    if [ $autostart -eq 0 ];then
        $SHELL_DIR/autostart_wine.sh $DEB_PACKAGE_NAME
    fi
}
###通用启动APP逻辑。对于没有被case捕捉的非适配APP，则直接执行此部分。似乎已经有了防止残留的功能
###一些自定义的应用不会使用这个启动，而另一些则会调用这个
###有设置mimetype和自动启动(这个暂时没分析)的功能

CallZhuMu()
{
    #change current dir to excute path
    path=$(dirname "$path")
    cd "$path"
    pwd

    #Set default mime type
    if [ -n "$MIME_TYPE" ]; then
        xdg-mime default "$DEB_PACKAGE_NAME".desktop "$MIME_TYPE"
    fi

    debug_log_to_file "Starting process $* ..."
    if [ -n "$2" ];then
        env WINEPREFIX="$WINEPREFIX" $WINE_CMD "$1" "--url=$2" &
    else
        env WINEPREFIX="$WINEPREFIX" $WINE_CMD "$1" &
    fi
}

CallQQGame()
{
    debug_log "run $1"
    $SHELL_DIR/kill.sh qqgame block
    env WINEPREFIX="$WINEPREFIX" $WINE_CMD "$1" &
}

CallQQ()
{
    if [ ! -f "$WINEPREFIX/../.QQ_run" ]; then
        debug_log "first run time"
        $SHELL_DIR/add_hotkeys
        $SHELL_DIR/fontconfig
        touch "$WINEPREFIX/../.QQ_run"
    fi

    DisableWrite "${WINEPREFIX}/drive_c/Program Files/Tencent/QQ/Bin/QQLiveMPlayer"
    DisableWrite "${WINEPREFIX}/drive_c/Program Files/Tencent/QQ/Bin/QQLiveMPlayer1"
    DisableWrite "${WINEPREFIX}/drive_c/Program Files/Tencent/QzoneMusic"

    DisableWrite "${WINEPREFIX}/drive_c/Program Files/Tencent/QQBrowser"
    DisableWrite "${WINEPREFIX}/drive_c/Program Files/Common Files/Tencent/QQBrowser"
    DisableWrite "${WINEPREFIX}/drive_c/users/Public/Application Data/Tencent/QQBrowserBin"
    DisableWrite "${WINEPREFIX}/drive_c/users/Public/Application Data/Tencent/QQBrowserDefault"
    DisableWrite "${WINEPREFIX}/drive_c/users/${USER}/Application Data/Tencent/QQBrowserDefault"

    DisableWrite "${WINEPREFIX}/drive_c/users/Public/Application Data/Tencent/QQPCMgr"
    DisableWrite "${WINEPREFIX}/drive_c/Program Files/Common Files/Tencent/QQPCMgr"

    DisableWrite "${WINEPREFIX}/drive_c/Program Files/Common Files/Tencent/HuaYang"
    DisableWrite "${WINEPREFIX}/drive_c/users/${USER}/Application Data/Tencent/HuaYang"

    CallProcess "$@"
}

CallTIM()
{
    if [ ! -f "$WINEPREFIX/../.QQ_run" ]; then
        debug_log "first run time"
        $SHELL_DIR/add_hotkeys
####似乎是给dde-control-center添加快捷键
        $SHELL_DIR/fontconfig
####暂时无法得知用途和用法
        # If the bottle not exists, run reg may cost lots of times
        # So create the bottle befor run reg
        env WINEPREFIX="$WINEPREFIX" $WINE_CMD uninstaller --list
        touch $WINEPREFIX/../.QQ_run
    fi

    CallProcess "$@"

    #disable Tencent MiniBrowser
    _DeleteRegistry "HKCU\\Software\\Tencent\\MiniBrowser"
}

CallWeChat()
{
    export DISABLE_RENDER_CLIPBOARD=1
    CallProcess "$@"
}

CallWangWang()
{
    chmod 700 "$WINEPREFIX/drive_c/Program Files/AliWangWang/9.12.10C/wwbizsrv.exe"
    chmod 700 "$WINEPREFIX/drive_c/Program Files/Alibaba/wwbizsrv/wwbizsrv.exe"
    if [ $# = 3 ] && [ -z "$3" ];then
        EXEC_PATH="c:/Program Files/AliWangWang/9.12.10C/WWCmd.exe"
        env WINEPREFIX="$WINEPREFIX" $WINE_CMD "$EXEC_PATH" "$2" &
    else
    	CallProcess "$@"
    fi
}

CallWXWork()
{
    if [ -d "${WINEPREFIX}/drive_c/users/${USER}/Application Data/Tencent/WXWork/Update" ]; then
        rm -rf "${WINEPREFIX}/drive_c/users/${USER}/Application Data/Tencent/WXWork/Update"
    fi
    if [ -d "${WINEPREFIX}/drive_c/users/${USER}/Application Data/Tencent/WXWork/upgrade" ]; then
        rm -rf "${WINEPREFIX}/drive_c/users/${USER}/Application Data/Tencent/WXWork/upgrade"
    fi
    #Support use native file dialog

    CallProcess "$@"
}

CallDingTalk()
{
    debug_log "run $1"
    $SHELL_DIR/kill.sh DingTalk block

    CallProcess "$@"
}



CallMeiTuXiuXiu()
{
    #set -- "$1" "${2#file://*}"
    local path=$(urldecode "$2")
    path=${path/file:\/\//}
    set -- "$1" "$path"
	if [ "$path" ];then 
    CallProcess "$@"
	else
	CallProcess "$1"
	fi
}

CallFastReadPDF()
{
    #set -- "$1" "${2#file://*}"
    local path=$(urldecode "$2")
    path=${path/file:\/\//}
    set -- "$1" "$path"
	if [ "$path" ];then 
    CallProcess "$@"
	else
	CallProcess "$1"
	fi
}

CallEvernote()
{
    #set -- "$1" "${2#file://*}"
    local path=$(urldecode "$2")
    path=${path/file:\/\//}
    set -- "$1" "$path"
	if [ "$path" ];then 
    CallProcess "$@"
	else
	CallProcess "$1"
	fi
}

CallTencentVideo()
{
    if [ -f "${WINEPREFIX}/drive_c/Program Files/Tencent/QQLive/Upgrade.dll" ]; then
        rm -rf "${WINEPREFIX}/drive_c/Program Files/Tencent/QQLive/Upgrade.dll"
    fi

    CallProcess "$@"
}

CallFoxmail()
{
    sed -i '/LogPixels/d' ${WINEPREFIX}/user.reg
    CallProcess "$@"
}

CallTHS()
{
    $SHELL_DIR/kill.sh ths block

    debug_log "Start run $1"
    #get file full path
    path="$1"
    path=$(echo ${path/c:/${WINEPREFIX}/drive_c})
    path=$(echo ${path//\\/\/})

    #kill bloack process
    name="${path##*/}"
    $SHELL_DIR/kill.sh "$name" block

    #change current dir to excute path
    path=$(dirname "$path")
    cd "$path"
    pwd

    #Set default mime type
    if [ -n "$MIME_TYPE" ]; then
        xdg-mime default "$DEB_PACKAGE_NAME".desktop "$MIME_TYPE"
    fi

    env WINEPREFIX="$WINEPREFIX" $WINE_CMD "$@" &
}

CallQQGameV2()
{
    debug_log "run $1"
    $SHELL_DIR/kill.sh QQMicroGameBox block
    env WINEPREFIX="$WINEPREFIX" $WINE_CMD "$1" -action:force_download -appid:${2} -pid:8 -bin_version:1.1.2.4 -loginuin: &
}

CallPsCs6()
{
    #get file full path
    path="$1"
    path=$(echo ${path/c:/${WINEPREFIX}/drive_c})
    path=$(echo ${path//\\/\/})

    #kill bloack process
    name="${path##*/}"
    $SHELL_DIR/kill.sh "$name" block

    #change current dir to excute path
    path=$(dirname "$path")
    cd "$path"
    pwd

    #Set default mime type
    if [ -n "$MIME_TYPE" ]; then
        xdg-mime default "$DEB_PACKAGE_NAME".desktop "$MIME_TYPE"
    fi

    debug_log_to_file "Starting process $* ..."

    env WINEPREFIX="$WINEPREFIX" $WINE_CMD "$@" &
}

#arg 1: exec file path
#arg 2: autostart ,or exec arg 1
#arg 3: exec arg 2
CallApp()
{
    FixLink
    debug_log "CallApp $BOTTLENAME arg count $#: $*"

    case $BOTTLENAME in
        "Deepin-WangWang")
            CallWangWang "$@"
            ;;
        "Deepin-ZhuMu")
            CallZhuMu "$@"
            ;;
        "Deepin-QQ"|"Wine-QQ"|"Spark-QQ")
            CallQQ "$@"
            ;;
        "Deepin-TIM")
            CallTIM "$@"
            ;;
        "Deepin-QQGame"*)
            CallQQGame "$@"
            ;;
        "Deepin-ATM")
            CallATM "$@"
            ;;
        "Deepin-WeChat")
            CallWeChat "$@"
            ;;
        "Deepin-WXWork")
            CallWXWork "$@"
            ;;
        "Deepin-Dding")
            CallDingTalk "$@"
            ;;
        "Deepin-MTXX")
            CallMeiTuXiuXiu "$@"
            ;;
        "Deepin-FastReadPDF")
            CallFastReadPDF "$@"
            ;;
        "Deepin-Evernote")
            CallEvernote "$@"
            ;;
        "Deepin-TencentVideo")
            CallTencentVideo "$@"
            ;;
        "Deepin-Foxmail")
            CallFoxmail "$@"
            ;;
        "Deepin-THS")
            CallTHS "$@"
            ;;
        "Deepin-QQHlddz")
            CallQQGameV2 "$1" 363
            ;;
        "Deepin-QQBydr")
            CallQQGameV2 "$1" 1104632801
            ;;
        "Deepin-QQMnsj")
            CallQQGameV2 "$1" 1105856612
            ;;
        "Deepin-QQSszb")
            CallQQGameV2 "$1" 1105640244
            ;;
        "Deepin-CS6")
            CallPsCs6 "$@"
            ;;
        *)
            CallProcess "$@"
            ;;
    esac
}
ExtractApp()
{
	mkdir -p "$1"
	7z x "$APPDIR/$APPTAR" -o"$1"
	mv "$1/drive_c/users/@current_user@" "$1/drive_c/users/$USER"
	sed -i "s#@current_user@#$USER#" $1/*.reg
    FixLink
}
DeployApp()
{
	ExtractApp "$WINEPREFIX"

    if UsePublicDir;then
        chgrp -R users "$WINEPREFIX"
        chmod -R 0775 "$WINEPREFIX"
    fi

	echo "$APPVER" > "$WINEPREFIX/PACKAGE_VERSION"

}
RemoveApp()
{
	rm -rf "$WINEPREFIX"
}
ResetApp()
{
	debug_log "Reset $PACKAGENAME....."
	read -p "*	Are you sure?(Y/N)" ANSWER
	if [ "$ANSWER" = "Y" -o "$ANSWER" = "y" -o -z "$ANSWER" ]; then
		EvacuateApp
		DeployApp
		CallApp
	fi
}
UpdateApp()
{
	if [ -f "$WINEPREFIX/PACKAGE_VERSION" ] && [ "$(cat "$WINEPREFIX/PACKAGE_VERSION")" = "$APPVER" ]; then
		return
	fi
	if [ -d "${WINEPREFIX}.tmpdir" ]; then
		rm -rf "${WINEPREFIX}.tmpdir"
	fi

    case $BOTTLENAME in
        "Deepin-Intelligent" | "Deepin-QQ" | "Deepin-TIM" | "Deepin-WeChat" | "Deepin-WXWork" | "Deepin-Dding")
            rm -rf "$WINEPREFIX"
            DeployApp
            return
            ;;
    esac

	ExtractApp "${WINEPREFIX}.tmpdir"
	$SHELL_DIR/updater -s "${WINEPREFIX}.tmpdir" -c "${WINEPREFIX}" -v

    if UsePublicDir;then
        chgrp -R users "$WINEPREFIX"
        chmod -R 0775 "$WINEPREFIX"
    fi

	rm -rf "${WINEPREFIX}.tmpdir"
	echo "$APPVER" > "$WINEPREFIX/PACKAGE_VERSION"
}
RunApp()
{
    progpid=$(ps -ef | grep "zenity --progress --title=${BOTTLENAME}" | grep -v grep)
    debug_log "run ${BOTTLENAME} progress pid $progpid"
    if [ -n "$progpid" ]; then
        debug_log "$BOTTLENAME is running"
        exit 0
    fi
 	if [ -d "$WINEPREFIX" ]; then
        UpdateApp | progressbar "$BOTTLENAME" "更新$BOTTLENAME中..."
 	else
        DeployApp | progressbar $BOTTLENAME "初始化$BOTTLENAME中..."
 	fi
#############  WARNING: Here is the modified content: Now will run set-dwine-scale.sh
	/opt/durapps/spark-dwine-helper/set-dwine-scale.sh "$WINEPREFIX"

    CallApp "$@"
}

CreateBottle()
{
    if [ -d "$WINEPREFIX" ]; then
        UpdateApp
    else
        DeployApp
    fi
}

ParseArgs()
{
    if [ $# -eq 4 ];then
	    RunApp "$3"
    elif [ $# -eq 5 ];then
	    RunApp "$3" "$5"
    else
	    RunApp "$3" "$5" "$6"
    fi
}

init_log_file

# Check if some visual feedback is possible
if command -v zenity >/dev/null 2>&1; then
	progressbar()
	{
		WINDOWID="" zenity --progress --title="$1" --text="$2" --pulsate --width=400 --auto-close --no-cancel ||
		WINDOWID="" zenity --progress --title="$1" --text="$2" --pulsate --width=400 --auto-close
	}

else
	progressbar()
	{
		cat -
	}
fi


#####准备启动进程，分析在 https://shenmo7192.gitee.io/post/deepin-wine6%E7%9A%84run_v4%E8%84%9A%E6%9C%AC%E6%8E%A2%E7%B4%A2%E5%90%AF%E5%8A%A8%E6%96%B9%E5%BC%8F/
if [ $# -lt 3 ]; then
    debug_log "参数个数小于3个"
    exit 0
fi

BOTTLENAME="$1"
WINEPREFIX="$HOME/.deepinwine/$1"

if UsePublicDir;then
    WINEPREFIX="$PUBLIC_DIR/$1"
fi

APPDIR="/opt/apps/${DEB_PACKAGE_NAME}/files"
if [ -f "$APPDIR/files.md5sum" ];then
    APPVER="$(cat $APPDIR/files.md5sum)"
else
    APPVER="$2"
fi

debug_log "Run $*"

#执行lnk文件通过判断第5个参数是否是“/Unix”来判断
if [ "$4" == "/Unix" ];then
    RunApp "$3" "$4" "$5"
    exit 0
fi

if [ $# -lt 4 ]; then
	RunApp "$3"
	exit 0
fi
case $4 in
	"-r" | "--reset")
		ResetApp
		;;
	"-c" | "--create")
		CreateBottle
		;;
	"-e" | "--remove")
		RemoveApp
		;;
	"-u" | "--uri")
        ParseArgs "$@"
		;;
	"-f" | "--file")
        ParseArgs "$@"
		;;
	"-h" | "--help")
		HelpApp
		;;
	*)
		echo "Invalid option: $4"
		echo "Use -h|--help to get help"
		exit 1
		;;
esac
exit 0
