<?php
session_start();

// Exibe os erros para depuração
ini_set('display_errors', 1);
error_reporting(E_ALL);

// Verifica se o usuário está logado e se é o administrador
if (!isset($_SESSION['user_id']) || $_SESSION['email'] != 'admin@admin') {
    header("Location: login.php");
    exit();
}

require_once 'config.conf';  // Conexão com o banco de dados

// Conectar ao banco de dados
$conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
if ($conn->connect_error) {
    die("Conexão falhou: " . $conn->connect_error);
}

// Funções para obter usuários e planos
function obterUsuarios($conn) {
    $sql = "SELECT usuarios.id, usuarios.email, usuarios.enabled, planos.nome AS plano_nome
            FROM usuarios
            LEFT JOIN planos ON usuarios.plano = planos.id
            WHERE usuarios.email != 'admin@admin'"; // Não listar o administrador
    return $conn->query($sql);
}

function obterPlanos($conn) {
    $sql = "SELECT id, nome, prazo FROM planos";  // Agora inclui a coluna 'prazo'
    return $conn->query($sql);
}

// Função para excluir um plano
if (isset($_POST['delete_plan_id'])) {
    $plan_id = $_POST['delete_plan_id'];
    $sql = "DELETE FROM planos WHERE id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $plan_id);
    if ($stmt->execute()) {
        echo "<script>alert('Plano excluído com sucesso!'); window.location = 'admin_page.php?action=edit_plans';</script>";
    } else {
        echo "<script>alert('Erro ao excluir plano: " . $conn->error . "'); window.location = 'admin_page.php?action=edit_plans';</script>";
    }
    exit();
}

// Salvar alterações de plano
if (isset($_POST['save_plan'])) {
    $nome = $conn->real_escape_string($_POST['nome']);
    $prazo = $_POST['prazo'];
    $id_plano = $_POST['id_plano'];

    // Atualizar plano
    $sql = "UPDATE planos SET nome = '$nome', prazo = $prazo WHERE id = $id_plano";
    if ($conn->query($sql) === TRUE) {
        echo "Plano atualizado com sucesso.";
    } else {
        echo "Erro ao atualizar plano: " . $conn->error;
    }
}

// Função para atualizar plano de usuário
if (isset($_POST['id_usuario']) && isset($_POST['plano_id'])) {
    $id_usuario = $_POST['id_usuario'];
    $plano_id = $_POST['plano_id'];
    // Atualiza o plano do usuário
    $sql = "UPDATE usuarios SET plano = ? WHERE id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ii", $plano_id, $id_usuario);
    if ($stmt->execute()) {
        echo "Plano do usuário atualizado com sucesso!";
    } else {
        echo "Erro ao atualizar plano: " . $conn->error;
    }
}

// Função para adicionar um novo plano
if (isset($_POST['novo_nome']) && isset($_POST['novo_prazo'])) {
    $novo_nome = $_POST['novo_nome'];
    $novo_prazo = $_POST['novo_prazo'];
    // Adiciona o novo plano no banco
    $sql = "INSERT INTO planos (nome, prazo) VALUES (?, ?)";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("si", $novo_nome, $novo_prazo);
    if ($stmt->execute()) {
        echo "Plano adicionado com sucesso!";
    } else {
        echo "Erro ao adicionar plano: " . $conn->error;
    }
}

// Função para adicionar um novo usuario
if (isset($_POST['salvar_usuario'])) {
    $email = $_POST['email'];
    $senha = password_hash($_POST['senha'], PASSWORD_BCRYPT); // Gerar hash da senha
    $plano = $_POST['plano'];

    $sql = "INSERT INTO usuarios (email, senha, plano, enabled) VALUES (?, ?, ?, 1)";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ssi", $email, $senha, $plano);

    if ($stmt->execute()) {
        echo "<script>alert('Usuário criado com sucesso!'); window.location = 'admin_page.php?action=edit_users';</script>";
    } else {
        echo "<script>alert('Erro ao criar o usuário: " . $conn->error . "'); window.location = 'admin_page.php?action=edit_users';</script>";
    }
}

// Atualizar plano existente
if (isset($_POST['editar_plano_id'])) {
    $plano_id = $_POST['editar_plano_id'];
    $novo_nome = $_POST['novo_nome'];
    $novo_prazo = $_POST['novo_prazo'];

    // Verificar se o nome já existe em outro plano
    $sql_check = "SELECT id FROM planos WHERE nome = ? AND id != ?";
    $stmt_check = $conn->prepare($sql_check);
    $stmt_check->bind_param("si", $novo_nome, $plano_id);
    $stmt_check->execute();
    $stmt_check->store_result();

    if ($stmt_check->num_rows > 0) {
        echo "<script>alert('Erro: Já existe um plano com este nome. Escolha um nome diferente.'); window.history.back();</script>";
    } else {
        // Atualizar o plano no banco
        $sql_update = "UPDATE planos SET nome = ?, prazo = ? WHERE id = ?";
        $stmt_update = $conn->prepare($sql_update);
        $stmt_update->bind_param("sii", $novo_nome, $novo_prazo, $plano_id);
    
        if ($stmt_update->execute()) {
           echo "<script>alert('Plano atualizado com sucesso!'); window.location = 'admin_page.php?action=edit_plans';</script>";
        } else {
           echo "<script>alert('Erro ao atualizar plano: " . $conn->error . "'); window.location = 'admin_page.php?action=edit_plans';</script>";
        }
    }

}

// Verificar qual ação o administrador quer executar
$action = isset($_GET['action']) ? $_GET['action'] : 'dashboard';

//Fazer Logoff
if ($action === 'logoff') {
    session_unset(); // Remove todas as variáveis da sessão
    session_destroy(); // Destroi a sessão
    header("Location: login.php"); // Redireciona para a página de login
    exit();
}

$edit_plan_id = isset($_GET['edit_plan']) ? $_GET['edit_plan'] : null;

// Obter os dados necessários
$usuarios = obterUsuarios($conn);
$planos = obterPlanos($conn);
$plano_editar = null;
if ($edit_plan_id) {
    $sql = "SELECT * FROM planos WHERE id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $edit_plan_id);
    $stmt->execute();
    $plano_editar = $stmt->get_result()->fetch_assoc();
}
?>

<!DOCTYPE html>
<html lang="pt-br">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Painel Administrativo</title>
</head>
<body>

<h1>Painel Administrativo</h1>

<!-- Botão para voltar ao painel principal -->
<a href="admin_page.php?action=dashboard"><button>Voltar ao Painel</button></a>
<a href="admin_page.php?action=logoff"><button>Sair</button></a>

<!-- Menu de navegação -->
<ul>
    <li><a href="admin_page.php?action=dashboard">Dashboard</a></li>
    <li><a href="admin_page.php?action=edit_users">Gerenciar Usuários</a></li>
    <li><a href="admin_page.php?action=edit_plans">Gerenciar Planos</a></li>
</ul>

<?php if ($action == 'dashboard'): ?>
    <h2>Bem-vindo ao Painel Administrativo</h2>
    <p>Escolha uma opção no menu para gerenciar usuários ou planos.</p>

<?php elseif ($action == 'edit_users'): ?>
    <h2>Gerenciar Usuários</h2>
    <?php if ($usuarios->num_rows > 0): ?>
        <table border="1">
            <thead>
                <tr>
                    <th>E-mail</th>
                    <th>Status</th>
                    <th>Plano</th>
                </tr>
            </thead>
            <tbody>
                <?php while($usuario = $usuarios->fetch_assoc()): ?>
                    <tr>
                        <td><?= htmlspecialchars($usuario['email']) ?></td>
                        <td><?= htmlspecialchars($usuario['habilitado']) ?></td>
                        <td>
                            <!-- Formulário para alterar o plano do usuário -->
                            <form method="post" action="admin_page.php?action=edit_users">
                                <input type="hidden" name="id_usuario" value="<?= $usuario['id'] ?>">
                                <select name="plano_id">
                                    <?php
                                        // Voltar o ponteiro para o início da consulta para os planos
                                        $planos->data_seek(0);
                                        while ($plano = $planos->fetch_assoc()): ?>
                                            <option value="<?= $plano['id'] ?>" <?= $usuario['plano_nome'] == $plano['nome'] ? 'selected' : '' ?>>
                                                <?= htmlspecialchars($plano['nome']) ?>
                                            </option>
                                    <?php endwhile; ?>
                                </select>
                                <button type="submit" onclick="return alert('Plano do usuário atualizado com sucesso')">Alterar Plano</button>
                            </form>
                        </td>
                    </tr>
                <?php endwhile; ?>
            </tbody>
        </table>
    <?php else: ?>
        <p>Não há usuários cadastrados.</p>
    <?php endif; ?>

    <p><a href="admin_page.php?action=edit_users&create_user=true"><button>Criar Novo Usuário</button></a></p>

    <?php if (isset($_GET['create_user']) && $_GET['create_user'] == 'true'): ?>
        <h2>Criar Novo Usuário</h2>
        <form method="post" action="admin_page.php?action=edit_users">
            <label for="email">E-mail:</label>
            <input type="email" name="email" id="email" required><br><br>

            <label for="senha">Senha:</label>
            <input type="password" name="senha" id="senha" required><br><br>

            <label for="plano">Plano:</label>
            <select name="plano" id="plano" required>
                <?php
                    // Carregar os planos para escolher
                    $planos->data_seek(0); // Resetar o ponteiro do plano para começar do início
                    while ($plano = $planos->fetch_assoc()): ?>
                        <option value="<?= $plano['id'] ?>"><?= htmlspecialchars($plano['nome']) ?></option>
                <?php endwhile; ?>
            </select><br><br>

            <button type="submit" name="salvar_usuario">Salvar</button>
            <a href="admin_page.php?action=edit_users"><button type="button">Cancelar</button></a>
        </form>
    <?php endif; ?>

<?php elseif ($action == 'edit_plans'): ?>
    <h2>Gerenciar Planos</h2>

    <?php if ($edit_plan_id && $plano_editar): ?>
        <h3>Editar plano: <?= htmlspecialchars($plano_editar['nome']) ?></h3>
        <form method="post">
            <input type="hidden" name="id_plano" value="<?= $plano_editar['id'] ?>">

            <label for="novo_nome">Nome do Plano:</label>
            <input type="text" name="nome" id="nome" value="<?php echo $plano_editar['nome']; ?>" required><br><br>

            <label for="novo_prazo">Prazo (em dias):</label>
            <input type="number" name="prazo" value="<?php echo $plano_editar['prazo']; ?>" required><br><br>

            <button type="submit" name="save_plan" onclick="return alert('Plano atualizado com sucesso')">Salvar</button>
            <a href="admin_page.php?action=edit_plans"><button type="button">Cancelar</button></a>
        </form>

    <?php else: ?>

    <!-- Formulário para adicionar um novo plano -->
        <h3>Adicionar Novo Plano</h3>
        <form method="post" action="admin_page.php?action=edit_plans">
            <label for="novo_nome">Nome do Plano:</label>
            <input type="text" name="novo_nome" id="novo_nome" required><br><br>
            <label for="novo_prazo">Prazo (em dias):</label>
            <input type="number" name="novo_prazo" id="novo_prazo" required><br><br>
            <button type="submit">Adicionar Plano</button>
        </form>
  
        <br><br>

	<h3>Planos Existentes</h3>
	<table border="1">
            <thead>
                <tr>
                    <th>Nome</th>
                    <th>Prazo (em dias)</th>
                    <th></th>
                    <th></th>
                </tr>
            </thead>
	    <tbody>
                <?php while($plano = $planos->fetch_assoc()): ?>
                    <tr>
                        <td><?= htmlspecialchars($plano['nome']) ?></td>
                        <td><?= htmlspecialchars($plano['prazo']) ?></td> <!-- Exibe a coluna prazo -->
                        <td>
                            <a href="admin_page.php?action=edit_plans&edit_plan=<?= $plano['id'] ?>">Editar</a>
                        </td>
                        <td>
                            <!-- Formulário para excluir plano -->
                            <?php if ($plano['nome'] != 'Padrão (plano padrão)'): ?>
                                <form action="admin_page.php" method="post" style="display:inline;">
                                    <input type="hidden" name="delete_plan_id" value="<?= $plano['id']; ?>">
                                    <button type="submit" onclick="return confirm('Você tem certeza que deseja excluir este plano?')">Excluir</button>
                                </form>
                            <?php endif; ?>
                        </td>
                    </tr>
                <?php endwhile; ?>
	    </tbody>
	</table>


    <?php endif; ?>

<?php endif; ?>


</body>
</html>

<?php
$conn->close();
?>

