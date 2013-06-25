#!/home/zhangyunliu01/opbin/php-5.4.5/bin/php
<?php
    $old_db = 'nodes.old';
    $db = 'nodes';
    $db_user = 'root';
    $db_pwd = 'VxeBU1TDtoa-f6fiy-yt';

    $ISP = array('cm', 'cu', 'ct');
    $IDC = array('jx','tc','yf','ai','m1','cq01','db','st01','dbl','hd','hz01');
    $PLATFORM = array('n','n0','n1','e','e0','e1','e2','e3','e4','e5','e6','e7','e8','e9','e10','e11','e12','v','v0','v1','v2','v3','v4','v5','v6','vexp','sce','debug','deptest','deptest0','deptest1','deptest2','deptest3','deptest4','deptest5','deptest6','psdata00','imbp','nbase','d0','d','ads','ads0','ads1','captest','rolltest','bp','bid','bid0','bid1','d1','d2','d3','d4','f','f0','f1','l','l0','l1','ers','ers0','ers1','exps');
    $MODULE = array('imas','imbs','qs','retras','retrbs','asq','wasq','router','dq','sps','ems','nks','retrms','ecomda','ubcda','armor','ses','cookie','rms','drms','bvs','krii','usergate','pgems','hy','zcache','metaserver','asp','bs','retrmts','www','plsa','imdi','adrest','krbs');
    $GROUP = array('group0','group1','group2','group3','group4','group5','group6','group7');

    $segment = array('ISP', 'IDC', 'PLATFORM', 'MODULE', 'GROUP');

    function read($length=255){
        $fp = fopen('php://stdin', 'r');
        $line=fgets($fp,$length);
        fclose($fp);
        return trim($line);
    }

    function getConn($db) {
        global $db_user, $db_pwd;
        $conn = mysql_connect('ai-imci-control01.ai01.baidu.com:8908', $db_user, $db_pwd, true);
        mysql_query('SET NAMES UTF-8', $conn);
        mysql_select_db($db, $conn);
        return $conn;
    }

    //TRUNCATE TABLE
    echo 'This operation will erease all data in table:servers, tags, servers_tags!Are you sure?(y/N):';
    $confirm = read();
    if ($confirm != 'Y' && $confirm != 'y') exit;

    $conn = getConn($db);
    $conn_old = getConn($old_db);
    mysql_query("TRUNCATE TABLE `servers`", $conn);
    mysql_query("TRUNCATE TABLE `tags`", $conn);
    mysql_query("TRUNCATE TABLE `servers_tags`", $conn);

    //Insert tags
    echo "\033[1mClone tags\033[0m\n";
    $tag_res = mysql_query('SELECT DISTINCT `name`,`description` FROM `tags`', $conn_old);
    $tag_insert_sql = "INSERT INTO `tags` (`tag_segment_id`, `name`, `description`) VALUES ";

    $tag_insert_sql .= "(6, 'im', NULL),(6, 'shifen', NULL),"; //产品线tag处理。

    while ($tag = mysql_fetch_assoc($tag_res)) {

        echo "\t{$tag['name']}:";
        $tag['description'] = str_replace("'", '"', $tag['description']);

        $tag_segment = 'other';
        foreach ($segment as $seg) {
            if (in_array($tag['name'], $$seg)) {
                $tag_segment = $seg;
                break;
            }
        }
        if ($tag_segment == 'other') {
            echo 'Please specify the tag segment:';
            $tag_segment = read();
        }

        echo "segment:{$tag_segment}, description:{$tag['description']}.\n";

        $ts = mysql_fetch_assoc(mysql_query("SELECT * FROM `tag_segments` WHERE `name`='{$tag_segment}'", $conn));
        $sql = sprintf("(%d, '%s', %s),", $ts['id'], $tag['name'], empty($tag['description']) ? 'NULL' : "'{$tag['description']}'");
        $tag_insert_sql .= $sql;
    }
    $tag_insert_sql = substr($tag_insert_sql, 0, strlen($tag_insert_sql)-1);
    if (!mysql_query($tag_insert_sql, $conn)) {
        echo mysql_error($conn);
        exit;
    }

    //Insert Servers
    echo "\n\033[1mInsert Servers\033[0m\n";
    $server_res = mysql_query('SELECT DISTINCT `servers`.`name`,`servers`.`status`,`servers`.`id`,`projects`.`name` AS `project_name` FROM `servers`,`projects` WHERE `servers`.`project_id` = `projects`.`id`', $conn_old);
    while ($server = mysql_fetch_assoc($server_res)) {
        echo "\t{$server['name']}:";
        if (!mysql_query("INSERT INTO `servers` (`name`, `status`) VALUES ('{$server['name']}', '{$server['status']}')", $conn)) {
            echo "failed!\n";
        }
        echo 'success! update tags:';
        $sid = mysql_insert_id($conn);

        $tag_res = mysql_query("select * from `tags` where `id` in (select `tag_id` from `servers_tags` where `server_id`={$server['id']})", $conn_old);
        $tag_names = array(strtolower($server['project_name']));
        while ($tag = mysql_fetch_assoc($tag_res)) {
            array_push($tag_names, $tag['name']);
        }
        $tag_name_strs = implode("','", $tag_names);
        $tag_res = mysql_query("SELECT `id`,`name` FROM `tags` WHERE `name` IN ('{$tag_name_strs}')", $conn);
        $tag_sql = "INSERT INTO `servers_tags` (`server_id`, `tag_id`) VALUES ";
        while ($tag = mysql_fetch_assoc($tag_res)) {
            echo $tag['name'],',';
            $tag_sql .= sprintf("(%d, %d),", $sid, $tag['id']);
        }
        $tag_sql = substr($tag_sql, 0, strlen($tag_sql)-1);
        echo mysql_query($tag_sql, $conn) ? "success!\n" : "failed!\n";
    }
