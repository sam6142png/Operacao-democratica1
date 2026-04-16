# Cronograma Reformulado - Fase 1 (14/04 a 05/05)

Projeto: Operacao Democratica  
Foco: Programacao principal, sistema de missoes, missoes da Fase 1 e entrega jogavel

## Macro-objetivos ate 05/05

1. M1 - Nucleo sistemico minimo pronto
- MissionSystem + ChoiceSystem + estado global simples funcionando.

2. M2 - Fase 1 implementada de ponta a ponta
- Fluxo narrativo principal jogavel com ramificacoes essenciais.

3. M3 - Persistencia minima confiavel
- Save/Load preservando estado da missao e escolhas da fase.

4. M4 - Entrega apresentavel
- Build estavel da Fase 1 com checklist de demonstracao.

---

## Semana 1 (14/04 a 20/04) - M1: Nucleo sistemico minimo

Resultado esperado da semana: estrutura tecnica pronta para suportar missao e escolhas.

### 14/04 (Seg)
- Fechar escopo da Fase 1 (entra / nao entra).
- Definir estados de missao: locked, active, completed.
- Definir variaveis globais minimas: apoio_popular, exposicao_regime e flags centrais.

### 15/04 (Ter)
- Criar MissionManager (autoload) com API simples:
  - start_mission
  - advance_step
  - complete_mission
  - get_state
- Modelar a missao da Fase 1 em etapas claras.

### 16/04 (Qua)
- Criar ChoiceManager (autoload) para registrar escolhas-chave.
- Implementar leitura/escrita de flags em um ponto central.

### 17/04 (Qui)
- Integrar Dialogic com os managers por sinais/eventos.
- Validar 3 escolhas de teste alterando estado global.

### 18/04 (Sex)
- Criar HUD minima de objetivo atual (texto simples).
- Atualizar HUD quando etapa da missao mudar.

### 19/04 (Sab)
- Refatoracao leve (nomes consistentes, sem duplicacao).
- Documentar fluxo de uso dos managers para a equipe.

### 20/04 (Dom)
- Teste de regressao da base sistemica.
- Corrigir bugs criticos do nucleo.

---

## Semana 2 (21/04 a 27/04) - M2: Fase 1 ponta a ponta

Resultado esperado da semana: Fase 1 completa e jogavel do inicio ao fim.

### 21/04 (Seg)
- Quebrar o roteiro em blocos implementaveis (cena a cena).
- Definir caminho principal e ramificacoes obrigatorias.

### 22/04 (Ter)
- Preencher `m01_2 - vila  peixeiro.dtl` com fluxo principal.
- Conectar inicio/fim da timeline aos estados de missao.

### 23/04 (Qua)
- Implementar ramificacao: dizer a verdade vs mentir para o peixeiro.
- Garantir consequencia concreta (flag, fala alterada ou evento posterior).

### 24/04 (Qui)
- Implementar ramificacoes: quarto vs porao e chave verde vs dourada.
- Garantir retorno seguro para o fluxo principal.

### 25/04 (Sex)
- Implementar trecho de retorno ao velho.
- Encerrar formalmente a Fase 1 no MissionManager.

### 26/04 (Sab)
- Ligar escolhas da vila a variacoes de dialogo no final da fase.
- Validar ausencia de soft-lock nas rotas principais.

### 27/04 (Dom)
- Playtest completo da Fase 1 em pelo menos 2 caminhos.
- Corrigir travas de progressao.

---

## Semana 3 (28/04 a 05/05) - M3 e M4: Persistencia e entrega

Resultado esperado da semana: fase estavel, com save/load e pronta para apresentacao.

### 28/04 (Seg)
- Implementar Save/Load minimo.
- Persistir: etapa da missao, escolhas essenciais, variaveis globais basicas.

### 29/04 (Ter)
- Restaurar estado apos load sem quebrar dialogos.
- Testar retomada em 3 pontos criticos.

### 30/04 (Qua)
- Corrigir inconsistencias de continuidade narrativa apos carregar.
- Revisar checkpoints de missao.

### 01/05 (Qui)
- Polimento funcional: clareza de objetivo e feedback de progresso.

### 02/05 (Sex)
- Polimento tecnico: limpar scripts, padronizar nomes e organizar pastas de sistema.

### 03/05 (Sab)
- Playtest guiado por checklist de apresentacao.
- Classificar bugs por severidade: critico, medio, baixo.

### 04/05 (Dom)
- Corrigir bugs criticos e medios.
- Congelar escopo (sem adicionar novas features).

### 05/05 (Seg)
- Gerar build final da Fase 1.
- Executar checklist final e preparar roteiro de demonstracao.

---

## Criterios de sucesso por macro-objetivo

### M1 concluido quando:
- Missao inicia, progride e conclui por sistema.
- Escolhas gravam flags e afetam o fluxo.

### M2 concluido quando:
- Fase 1 fecha do inicio ao fim em rotas diferentes.
- Nao ha travamento de progressao.

### M3 concluido quando:
- Save/Load restaura estado de missao e escolhas.

### M4 concluido quando:
- Build roda de forma estavel e apresentavel.

---

## Regra de ouro (equipe escolar com verba apertada)

- Se nao ajuda a fechar a Fase 1 jogavel, adiar.
- Prioridade de execucao: funcionar > polir.
- Entrega forte e simples vale mais que sistema complexo incompleto.
