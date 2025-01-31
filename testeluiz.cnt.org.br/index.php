<?php
// Inclui o arquivo de configuração
require_once 'config.conf';

// Verifica o estado da instalação
if (defined('FIRSTINSTALL') && FIRSTINSTALL === 1) {
    header('Location: install.php');
    exit;
} else {
    header('Location: login.php');
    exit;
}
?>

