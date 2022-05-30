#!/bin/bash

help() {
    cat <<EOF
用法：$0 [-h|--help]  path
-h|--help     显示这个帮助
path          容器目录

这个脚本不应该用于deepin-wine6

--------------------------------------------------------------------
Usage: $0 [-h|--help] path
-h|--help     Show this text
path          Wine Container directory path

You shouldn't use this script with deepin-wine6

EOF
}
#########################帮助文件结束#############################

parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
        -h|--help)
            help
            exit
            ;;
        *)
            CONTAINER_PATH="$1"
		break
		#没有参数就读完退出
            ;;
    esac
    shift
    done
}
################
parse_args "$@"


#####先看看PATH对不对
if [ ! -f "$CONTAINER_PATH/user.reg" ];then
	echo "错误：找不到user.reg，退出。你应当在文件解压结束后调用此脚本"
    echo "E: Can not find user.reg. Exit. You should use this script after the extraction"
	exit 1
fi




until [ "$env_dwine_scale" != "" ];do
env_dwine_scale=`echo $DEEPIN_WINE_SCALE`
if [ "$env_dwine_scale" = "" ];then
echo "E: No DEEPIN_WINE_SCALE found. Use spark-dwine-scale-env-generator to generate"
echo "错误：没有检测到DEEPIN_WINE_SCALE，用spark-dwine-scale-env-generator生成"
/opt/durapps/spark-dwine-helper/spark-get-scale.sh $CONTAINER_PATH
env_dwine_scale=echo "$?"
else
echo "检测到的缩放倍数为:$env_dwine_scale"
echo "Scale is $env_dwine_scale"
fi

done
#####非deepin发行版似乎没有这个变量，暂时不清楚这个变量是哪个组件做的



case "$env_dwine_scale" in
       1.0)
            reg_text="\"LogPixels\"=dword:00000064"
            ;;
        1.25)
            reg_text="\"LogPixels\"=dword:0000007d"
            ;;
        1.5)
            reg_text="\"LogPixels\"=dword:00000096"
            ;;
        2.0)
            reg_text="\"LogPixels\"=dword:000000C8"
            ;;
	*)
		reg_text="\"LogPixels\"=dword:00000064"
		#可能不是Xorg
		;;
    esac

#####根据scale设置dword值


LogPixels_line=(`sed -n -e "/"LogPixels"/=" $CONTAINER_PATH/user.reg`)
#####关键词行数取得
until [ "${#LogPixels_line[@]}" = "0" ];do


line_num=${LogPixels_line[0]}

sed -i "$line_num"c\ "$reg_text" "$CONTAINER_PATH/user.reg"
LogPixels_line=(${LogPixels_line[@]:1})
done

echo "已经完成替换。位置：$CONTAINER_PATH/user.reg"
echo "在以下行数进行了替换，内容为$reg_text"
echo `sed -n -e "/"LogPixels"/=" $CONTAINER_PATH/user.reg`
echo "---------------------------------------"

