# 🥚 Vó Naná - Sistema de Gestão de Pedidos

Aplicação desenvolvida para gerenciamento de pedidos, logística e configurações de preços da empresa **Vó Naná – Ovos de Galinhas Livres**.

O sistema foi desenvolvido utilizando **Flutter** no front-end e integração com **PostgreSQL** no back-end, permitindo o gerenciamento de pedidos, pagamentos, relatórios e configurações administrativas.

---

## 📌 Funcionalidades

### Front-end (Flutter)
- 📋 Listagem de pedidos
- 🔎 Filtros por:
  - Data de entrega
  - Status do pedido
  - Status do pagamento
- 📄 Geração de relatório em PDF
- 🚚 Exportação de rotas de entrega
- ⚙️ Tela de configurações
- 💰 Alteração de preços dos produtos
- 📦 Configuração de frete

### Back-end / Banco de Dados
- 🔗 Conexão com PostgreSQL
- 🗄️ Consulta de pedidos
- 💳 Controle de pagamentos
- 📍 Consulta de endereços de entrega
- ⚙️ Persistência de configurações
- 📊 Manipulação de dados para relatórios

---

## 🛠️ Tecnologias Utilizadas

### Front-end
- Flutter
- Dart
- Material Design

### Back-end
- PostgreSQL
- Package `postgres`

### Bibliotecas Extras
- `pdf`
- `printing`
- `share_plus`
- `path_provider`
- `csv`

---

## 📂 Estrutura do Projeto

```txt
lib/
│── database/
│   └── database_helper.dart

│── services/
│   ├── pedido_service.dart
│   └── configuracao_service.dart

│── screens/
│   ├── home_screen.dart
│   ├── pedidos_screen.dart
│   └── configuracoes_screen.dart

│── widgets/
│   ├── card_pedido.dart
│   └── modal_filtros.dart

│── main.dart
```

---

## 📸 Funcionalidades do Sistema

- Gestão de pedidos
- Controle de entregas
- Relatórios em PDF
- Configuração de preços
- Gestão de frete
- Exportação de logística

---

## 👩‍💻 Desenvolvido por

**Autor(a):** TALIA DA SILVA BOSI

