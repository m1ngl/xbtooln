#!/usr/bin/env bash
######
#脚本网站:shell.xb6868.com
#论坛:bbs.xb6868.com
#github:https://github.com/myxuebi/xbtooln
#New maintainer: 一位无名无份的笨蛋(https://github.com/m1ngl)
function termux::setenv {
    export shell_url="https://raw.githubusercontent.com/myxuebi/xbtooln/master/files"
    export Y="\e[33m" # 转义字体-黄色
    export G="\e[32m" # 转义字体-绿色
    export R="\e[31m" # 转义字体-红色
    export E="\e[0m"  # 转义字体-隔断
    # 确认包管理器
    for i in apt pacman ; do
        if command -v $i &>/dev/null; then
            case $i in
                apt)
                    export update_pkg="apt update"
                    export install_pkg="apt install"
                    export remove_pkg="apt remove"
                    export automatic="-y" ;;
                pacman)
                    export update_pkg="pacman -Sy"
                    export install_pkg="pacman -S"
                    export remove_pkg="pacman -R"
                    export automatic="--noconfirm" ;;
            esac
        fi
    done
    export update_date=`date +"%D"`
    export verinfo="beta 0.0.1
                    只有基础termux功能
                    2022/9/1

                    2022/9/30
                    beta 0.0.2
                    修复已知bug

                    2022/10/4
                    beta 0.0.3
                    新增electron功能，修复已知bug

                    2022/12/17
                    beta 0.0.4
                    修复已知bug
                    优化chromium安装方式

                    2022/12/26
                    beta 0.0.5
                    优化容器安装方式
                    #增加chroot容器安装支持"
    # 确认容器位置
#    export os_distro=$(cat ~/../usr/etc/os-release | gawk 'NR==1' | gawk -F '"' '{print $2}' | gawk '{print $1}')
    export os_vendor=$(uname -o)

    # 输出日志专用函数
    function termux::stdout {
        color=$1
        strings=$2
        echo -e "${!color}${strings}${E}"
    }

    # 检测一个特定命令的返回值
    function termux::check::subcmd {
        cmd=$1
        shift
        arguments=$@
        echo $cmd $arguments
        { $cmd $arguments ;} \
        && termux::stdout G "子命令${cmd}返回了成功的结果" \
        || termux::stdout R "子命令${cmd}返回了失败的结果"
    }
}

function termux::preloader {
    # 预加载
    # 安装必须的软件
    local preinstall=(gawk dialog curl wget pulseaudio unzip)
    local missingpackage=
    for i in $preinstall; do
        if ! command -v $i &>/dev/null; then
            missingpackage+=" $i"
        fi
    done
    [ -n "$missingpackage" ] && eval $install_pkg $missingpackage $noconfirm
    [ $os_vendor = Android ] && termux::main
}

function termux::main {
    # Main主界面逻辑分发
    while true
    do
        main=$(dialog --title "Xbtooln Menu" --menu "你可以选择一个命令：" 0 0 0 \
        1 更换Termux的软件源 \
        2 备份/恢复Termux的文件 \
        3 安装一个Linux容器 \
        4 小工具-生成一个二维码 \
        5 关于我的脚本 --output-fd 1 || echo C)
        case $main in
            1)
                termux::changerepo ;;
            2)
                termux::backup/recovery ;;
            3)
                termux::install_a_container/selector ;;
            4)
                tools::create_a_qrcode ;;
            5)
                termux::about ;;
            C)
                termux::stdout Y "正在退出..."
		exit;;
        esac
    done
}

function termux::changerepo {
    while true
    do
        local subcmd=$(dialog --title "Xbtooln Menu" --menu "你可以选择一个源地址：" 0 0 0 \
        1 北京外国语大学-BFSU \
        2 清华大学-TUNA \
        3 中国科学技术大学-USTC \
        4 自定义... --output-fd 1 || echo C)
        case $subcmd in
            1)
                local mirror_url="deb https://mirrors.bfsu.edu.cn/termux/apt/termux-main stable main" ;;
            2)
                local mirror_url="deb https://mirrors.tuna.tsinghua.edu.cn/termux/apt/termux-main stable main" ;;
            3)
                local mirror_url="deb https://mirrors.ustc.edu.cn/termux/apt/termux-main stable main" ;;
            4)
                dialog --yesno "你即将进入termux-change-repo的界面，是否继续？" 0 0 && 
                termux-change-repo; return 0 ;;
            C)
                return 0 ;;
        esac
        termux::stdout Y "追加到文件..."
        sleep 0.5
        echo $mirror_url | tee -a $PREFIX/etc/apt/sources.list
        sleep 0.3
        apt update &&
        termux::stdout G "软件源被成功更换"
        sleep 0.5
        return 0
    done
}

function termux::backup/recovery {
    dialog --yesno "注意：恢复数据可能会覆盖当前的数据，确定要继续吗？" 0 0|| return 0
    while true
    do 
        local subcmd=$(dialog --title "Xbtooln Menu" --menu "你可以选择一个命令以进行下一步的操作" 0 0 0 \
        1 备份Termux现在的数据 \
        2 恢复存在的Termux的数据 --output-fd 1 || echo C)
        case $subcmd in 
            1)
                cd $PREFIX/../../
                tar zcvf backup_termux.tar.gz files
                mv backup_termux.tar.gz /sdcard/
                dialog --infobox "备份完成，你可以在按下回车键后回到主界面" 0 0
                return 0 ;;
            2)
                while true
                do
                    file=$(dialog --title "你可以使用空格键选中文件，然后按下回车选中" \
		    --fselect /sdcard/ \
                    7 40 --output-fd 1 || echo C)
                    [ "$file" = C ] && return 0
                    cd $PREFIX/../../
                    echo -e "${Y}正在检测文件有效性...${E}"
                    tar tf $file|grep -E '(home|usr)' &>/dev/null && 
                    { echo -e "${G}文件有效，可以解压${E}" 
                        cp $file ./recovery 
                        tar xvf recovery 
                        dialog --msgbox "恢复完成，现在你可以重新启动Termux" 0 0 
                        exit 0 ; } ||
                    { dialog --msgbox "这个文件似乎不是Termux的备份" 0 0 ; }
                done
			;;
            C)
                return 0 ;;
        esac
    done
}

function termux::install_a_container/selector {
    while true
    do
        local subcmd=$(dialog --title "Xbtooln Menu" \
        --menu "你现在需要选择一个类型的容器以安装\nNote: Chroot容器需要root权限" 0 0 0 \
        1 Chroot \
        2 Proot --output-fd 1|| echo C)
        [ "$subcmd" = C ] && return 0
        case $subcmd in
            1)
#                termux::install_a_container*generic/proot
#                [ -n "$new_root" ] &&
                termux::install_a_container/chroot ;;
            2)
                termux::install_a_container*generic/proot ;;
        esac
    done
}

function termux::install_a_container*generic/proot {
    while true
    do
        local subcmd=$(dialog --title "Xbtooln Menu" --menu "你可以在这里安装一个Linux容器" 0 0 0 \
        ubuntu 由Canonical公司开发的一个家用发行版 \
        debian 自由的GNU/Linux发行版 \
        archlinux 拱门邪教，法力无边（ --output-fd 1 || echo C)
        [ "$subcmd" = C ] && return 0
        local ver=$(curl https://mirrors.bfsu.edu.cn/lxc-images/${subcmd}/ | gawk -F ">" '{print $3}' |
        grep title | gawk '{print $2}' | gawk -F '"' '{print $2}' | sed 's/\///')
        for i in cosmic disco eoan groovy hirstue trusty
        do
        # 这里我实在是搞不懂雪碧大佬的逻辑，于是保留
        # 只作小小修改
            local ver=($(sed "/^$i/d" < <(echo "$ver")))
        done
        ver=$(echo "$ver" | cat -n | gawk '{print $2,$1}')
        case $subcmd in
            ubuntu|debian)
                while true
                do
                    local proot_ver=$(dialog --title "Xbtooln Menu" --menu "你可以在这里选择一个容器的版本" 0 0 0 \
                    $ver --output-fd 1 || echo C)
                    [ "$proot_ver" = C ] && return 0
                done ;;
            archlinux)
                local proot_ver=current ;;
        esac
        [ -e .${subcmd}-${proot_ver} ] &&
        { termux::stdout R "你已经安装过这个容器了"
          return 1 ; }

        # Preloader
        { 
            export link=$(curl https://mirrors.bfsu.edu.cn/lxc-images/images/${proot_system}/${proot_ver}/arm64/default/ \
            | gawk '{print $3}' \
            | tail -n 3 \
            | head -n 1 \
            | gawk -F '"' '{print $2}' \
            | gawk -F '/' '{print $1}') ;
            # 我觉得是提前删除存在的文件
            termux::stdout Y "等下可能要删除名字为\"rootfs.tar.xz\"的先前存在的文件" ;
            termux::stdout R "按任意键继续，或者Ctrl-C先退出脚本（在这个rootfs文件对你很重要的情况下）" ;
            read S -n 1
            [ -e rootfs.tar.xz ] && rm rootfs.tar.xz ; }

        export new_root=.${subcmd}-${proot_ver}
        termux::check::subcmd wget https://mirrors.bfsu.edu.cn/lxc-images/images/${proot_system}/${proot_ver}/arm64/default/${DOWN_LINE}/rootfs.tar.xz -t 4
        mkdir $new_root
        tar xpvf rootfs.tar.xz $new_root
        rm rootfs.tar.xz $new_root/etc/resolv.conf
        termux::stdout Y "追加DNS解析到resolv.conf..."
        tee <<< "nameserver 114.114.114.114
        nameserver 114.114.115.115" $new_root/etc/resolv.conf

        sleep 0.2
        termux::strout Y "修改容器的镜像源..."
        case $subcmd in
            ubuntu)
                 sed -i 's/ports.ubuntu.com/mirrors.ustc.edu.cn/g' \
                    $new_root/etc/apt/sources.list;;
            debian)
                sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' \
                    $new_root/etc/apt/sources.list;;
            archlinux)
                tee <<< 'Server = https://mirrors,ustc.edu.cn/archlinuxarm/$arch/$repo' \
                    $new_root/etc/pacman.d/mirrorlist
                tee <<< '[archlinuxcn]
                SigLevel = TrustAll
                Server = https://mirrors.ustc.edu.cn/$repo/$arch' \
                    $new_root/etc/pacman.conf ;;
        esac

        tee <<< "source run.sh" $new_root/etc/profile
        tee <<< "proot_system=${subcmd}" $new_root/root/run.sh

        sleep 0.3
        termux::stdout Y "追加启动脚本..."
        tee $new_root/root/run.sh \
        <<-'ADD'
case $proot_system in
    ubuntu|debian)
        apt install apt-transport-https
        perlpath=$(ls /usr/bin \
        |grep perl \
        |grep "[0-9]$")
        ln -s /usr/bin/$perlpath /usr/bin/perl
        apt install ca-certificates -y
        sed -i 's/http/https/g' /etc/apt/sources.list
        apt update
        touch ${HOME}/.hushlogin
        apt install vim fonts-wqy-zenhei tar pulseaudio \
            curl wget gawk whiptail locales busybox -y
        { mv /var/lib/dpkg/info /var/lib/dpkg/info_old \
        && mkdir /var/lib/dpkg/info \
        && apt-get update \
        && apt-get -f install \
        && mv /var/lib/dpkg/info/* /var/lib/dpkg/info_old/ \
        && mv /var/lib/dpkg/info /var/lib/dpkg/info_back \
        && mv /var/lib/dpkg/info_old /var/lib/dpkg/info ; }
        # 这里无法理解雪碧的想法，随缘吧
        apt install
        yes | apt reinstall sudo ;;
    archlinux)
        { chmod -R 755 /etc
          chmod 440 /etc/sudoers
          chmod -R 755 /usr
          chmod -R 755 /var
          sed -i 's/C/zh_CN.UTF-8/g' /etc/locale.conf
          pacman -Sy curl wget tar pulseaudio gawk \
            libnewt dialog wqy-zenhei vim nano busybox --noconfirm ; } ;;
esac
ADD
    done
}

function termux::install_a_container/chroot {
    # Detect root
    $install_pkg busybox tsu $automatic
    [ $(sudo id -u &>/dev/null) -eq 0 ] || {
        termux::stdout R "在你的设备检测不到Root权限"
        termux::stdout R "这可能是你的设备未Root或你刚才禁用了Termux的Root权限"
        termux::stdout Y "按任意键继续..."
        read S -n 1
        unset S
        return 1 ; }
    termux::install_a_container*generic/proot
    while true
    do
        local user=$(dialog --title "Chroot容器安装" \
        --inputbox "你需要输入一个用户名作为容器的普通用户(即uid不等于0的用户)\nNote: 这个普通用户很重要，请尽量键入英文以免产生问题" \
        0 0 0 --output-fd 1 || echo F07CB236FE)
	[ "$user" = F07CB236FE ] \
	&& return 0
        [ -z "$user" ] \
        && { termux::stdout R "不行，你键入了空白的用户名，按任意键回到输入界面..."
        read -n 1 S
        unset S ; } \
        || break
    done
}
termux::setenv
termux::stdout R "错误消息"
termux::stdout Y "警告消息"
termux::stdout G "成功消息"
sleep 1
termux::stdout G "现在是Debug时间！"
sleep 3
termux::preloader
