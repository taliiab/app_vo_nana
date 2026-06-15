# 🥚 Vó Naná - Painel Administrativo

Sistema administrativo desenvolvido em **Flutter** para gerenciamento de pedidos e configurações da empresa **Vó Naná – Ovos de Galinhas Livres 🐔**.

O sistema permite acompanhar pedidos, aplicar filtros logísticos e gerenciar configurações de preços e fretes de forma simples e intuitiva.

---

## 📱 Funcionalidades

### 📦 Gerenciamento de Pedidos
- Visualização de pedidos cadastrados
- Status de entrega:
    - Pendente
    - Entregue
    - Cancelado
- Informações do pedido:
    - ID do cliente
    - Quantidade de dúzias
    - Forma de pagamento
    - Valor subtotal
    - Valor do frete
    - Valor total
- Atualização via **pull-to-refresh**
- Filtro por período de entrega

### 🔎 Sistema de Filtros
Permite filtrar pedidos por:

#### 📅 Data de Entrega
- Data inicial
- Data final

#### 🚚 Status do Pedido
- Pendente
- Entregue
- Cancelado

#### 💳 Status do Pagamento
- Aprovado
- Pendente

---

### ⚙️ Configurações do Sistema

Gerenciamento das configurações administrativas:

- Valor da dúzia de ovos
- Valor do jumbo
- Valor do frete padrão
- Quantidade mínima para frete grátis

As alterações são salvas diretamente no banco de dados.

---

## 🛠️ Tecnologias Utilizadas

- **Flutter**
- **Dart**
- **PostgreSQL**
- **Material Design**
- Conexão com banco de dados via `DatabaseHelper`

---

## 🗂️ Estrutura do Projeto

```bash
lib/
│── database_helper.dart
│── home_screen.dart
│── main.dart
```

---

## 🎨 Interface

O sistema possui:

- Interface simples e intuitiva
- Navegação inferior (Bottom Navigation)
- Tema visual personalizado da Vó Naná
- Modal de filtros
- Atualização dinâmica de dados

---

## 🧱 Banco de Dados

O sistema utiliza tabelas como:

### `pedidos`
Responsável pelos dados principais dos pedidos.

### `itens_pedido`
Armazena quantidade dos produtos do pedido.

### `pagamentos`
Gerencia método e status do pagamento.

### `produtos`
Contém preços dos produtos.

### `configuracoes`
Armazena parâmetros administrativos do sistema.

---

## 🚀 Como Executar

### 1. Clonar o repositório

```bash
git clone https://github.com/taliiab/app_vo_nana
```

### 2. Entrar no projeto

```bash
cd app_vo_nana
```

### 3. Instalar dependências

```bash
flutter pub get
```

### 4. Executar o projeto

```bash
flutter run
```

---

## ⚙️ Configuração do Banco

Configure a conexão no arquivo:

```dart
database_helper.dart
```

Adicione os dados do seu banco PostgreSQL:

- Host
- Porta
- Usuário
- Senha
- Nome do banco

---

## 📌 Objetivo do Projeto

Este projeto foi desenvolvido com o objetivo de auxiliar no gerenciamento logístico e administrativo da empresa **Vó Naná**, facilitando o acompanhamento de pedidos e controle de configurações operacionais.

---

## 👨‍💻 Autor

Desenvolvido por **Talia Bosi**  
Curso de Sistemas para Internet