: ${CBD_BINARY:=$PWD/build/$(uname)/cbd}

setup() {
    : ${CBD_TMPDIR:=$(mktemp -d delme-XXXXXX)}
    
    if ! [ -f "$CBD_TMPDIR/Profile" ]; then
        cd $CBD_TMPDIR
        $CBD_BINARY init
    else
        cd $CBD_TMPDIR
        ls -1 | grep -v Profile | xargs rm -rf
    fi
}

teardown() {
    cd ..
}

T_checkRunnable() {
    $CBD_BINARY --version &>/dev/null
}

T_checkVersion() {
    ver=$($CBD_BINARY --version| sed "s/.* \([0-9]\+\)\.\([0-9]\+\)\.\([0-9]\+\)-.*/\1\2\3/")

    [[ $ver -gt 100 ]]
}

T_generate() {
    setup
    $CBD_BINARY generate
    exitCode=$?
    if ! [ -f docker-compose.yml ]; then
        $T_fail "docker-compose.yml didnt generated"
        return
    fi
    if ! [ -f uaa.yml ]; then
        $T_fail "uaa.yml didnt generated"
        return
    fi

    teardown

}

T_regenerateShouldCreate() {
    setup
    $CBD_BINARY regenerate

    if ! [ -f docker-compose.yml ]; then
        $T_fail "docker-compose.yml didnt generated"
        return
    fi
    if ! [ -f uaa.yml ]; then
        $T_fail "uaa.yml didnt generated"
        return
    fi

    teardown
}

T_regenerateShouldntBackupIfNoChanges() {
    setup
    $CBD_BINARY generate
    $CBD_BINARY regenerate

    if [ $(ls -1 docker-compose* | wc -l) -gt 1 ]; then
        $T_fail "there should be no backup files: docker-compose-XXXX.yml "
        return
    fi

    if [ $(ls -1 uaa* | wc -l) -gt 1 ]; then
        $T_fail "there should be no backup files: uaa-XXXX.yml "
        return
    fi
    
    teardown
}

T_regenerateShouldBackup() {
    setup
    $CBD_BINARY generate
    echo "export PUBLIC_IP=$(($RANDOM % 255)).$(($RANDOM % 255)).$(($RANDOM % 255)).$(($RANDOM % 255))" > Profile
    echo "export UAA_DEFAULT_USER_PW=$(base64 <<<$RANDOM)" >> Profile

    $CBD_BINARY regenerate

    if [ $(ls -1 docker-compose* | wc -l) -lt 2 ]; then
        $T_fail "there should be a backup: docker-compose-XXXX.yml "
        return
    fi

    if [ $(ls -1 uaa* | wc -l) -lt 2 ]; then
        $T_fail "there should be a backup: uaa-XXXX.yml "
        return
    fi
    
    teardown
}


