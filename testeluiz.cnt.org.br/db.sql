-- Criar tabela de usuários
CREATE TABLE IF NOT EXISTS usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    senha VARCHAR(255) NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT 0,
    plano INT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Criar tabela de rotas
CREATE TABLE IF NOT EXISTS rotas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(255) NOT NULL UNIQUE,
    id_usuario INT NOT NULL,
    url_destino VARCHAR(2083) NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT 1,    
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id) ON DELETE CASCADE
);

-- Criar tabela de planos
CREATE TABLE IF NOT EXISTS planos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(255) NOT NULL UNIQUE,
    prazo INT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- INSERT INTO planos (nome, prazo) 
-- SELECT * FROM (SELECT 'Padrão (plano padrão)', 30) AS tmp 
-- WHERE NOT EXISTS (SELECT 1 FROM planos WHERE nome = 'Padrão (plano padrão)') LIMIT 1;

-- Inserir o plano padrão
INSERT INTO planos (nome, prazo) VALUES ('Padrão (plano padrão)', 30);

-- Criar tabela de logs_redirect
CREATE TABLE IF NOT EXISTS logs_redirect (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_email VARCHAR(255) NOT NULL,
    rota_nome VARCHAR(255) NOT NULL,
    rota_created_at DATETIME,
    plano_nome VARCHAR(255) NOT NULL,
    plano_prazo INT NOT NULL,
    rota_id INT NOT NULL,
    data_acesso DATETIME DEFAULT CURRENT_TIMESTAMP,
    redirect_to TEXT NOT NULL,
    remote_addr TEXT NOT NULL,
    real_ip TEXT NOT NULL,
    FOREIGN KEY (rota_id) REFERENCES rotas(id) ON DELETE SET NULL
);

-- Criar índices para melhorar a performance
CREATE INDEX idx_usuarios_email ON usuarios (email);
CREATE INDEX idx_rotas_nome ON rotas (nome);
CREATE INDEX idx_rotas_id_usuario ON rotas (id_usuario);
CREATE INDEX idx_logs_id_usuario ON logs_redirect (id_usuario);

