-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

--> Esconde a barra de status do dispositivo
display.setStatusBar( display.HiddenStatusBar )

--> Adiciona faixas de áudio
local mainSound = audio.loadSound("sweetdreams.mp3")
local gunSound = audio.loadSound("lasergun.mp3")
local explSound = audio.loadSound("explosion.mp3")
audio.play(mainSound, {loops = -1, fade = 500})

local physics = require ("physics")
physics.start()
--> Sem gravidade porque o jogo acontece no espaço
physics.setGravity(0, 0)

--> Inicializa gerador de números aleatórios que será usado para
-- criar asteróides na tela
math.randomseed(os.time())

--> Configura a folha de imagens (para os sprites)
local sheetOptions =
{
  --> Como todas as imagens estão em um só sheet, criamos 5 elementos diferentes
  -- dentro da nossa tabela, cada um com os parâmetros (x, y, width, height),
  -- sendo x a posição superior esquerda da coordenada x da imagem no sheet e
  -- y a posição superior esquerda da coordenada y, ou seja o ponto inicial da
  -- imagem no sheet. O final é definido pelo width e o height.
  frames =
  {
    { --> 1) asteróide #1
      x = 0,
      y = 0,
      width = 102,
      height = 85
    },
    { --> 2) asteróide #2
      x = 0,
      y = 85,
      width = 90,
      height = 83
    },
    { --> 3) asteróide #3
      x = 0,
      y = 168,
      width = 100,
      height = 97
    },
    { --> 4) nave
      x = 0,
      y = 265,
      width = 98,
      height = 79
    },
    { --> 5) laser
      x = 98,
      y = 265,
      width = 14,
      height = 40
    }
  },
}

--> Carrega a folha de imagens
local objectSheet = graphics.newImageSheet("gameObjects.png", sheetOptions)

--> Inicializa as variáveis
local lives = 3
local score = 0
local died = false

local asteroidsTable = {}

local ship
local gameLoopTimer
local livesText
local scoreText
local OMGText

--> Setando os grupos de display que controlam e organizam as camadas de imagem.
-- A órdem em que os grupos são setados importa, pois também será a ordem em que
-- eles serão exibidos, ou seja, o que vem em seguida, irá sobrepor o anterior
local backgroup = display.newGroup() --> Grupo para o background
local mainGroup = display.newGroup() --> Grupo para nave, asteróides, lasers, etc
local uiGroup = display.newGroup() --> Grupo para objetos de UI, como pontuação e outros

--> Carrega a imagem do background e a insere no grupo "backgroup"
local background = display.newImageRect(backgroup, "background.png", 800, 1400)
background.x = display.contentCenterX
background.y = display.contentCenterY

--> O terceiro parâmetro passado é o número do frame definido com base na órdem
-- em que foram declarados na folha de imagens (objectSheet). Os dois últimos
-- parâmetros são largura e altura respectivamente
ship = display.newImageRect(mainGroup, objectSheet, 4, 98, 79)
ship.x = display.contentCenterX
ship.y = display.contentHeight - 100
--> "isSensor" define a nave como um objeto sensor, pra que ela detecte
-- colisões com outros objetos que também possuem física
physics.addBody(ship, {radius = 30, isSensor = true})
--> Nomeia o objeto pra uso futuro
ship.myName = "ship"

--> ".." serve para concatenação
livesText = display.newText( uiGroup, "Lives: " .. lives, 200, 80, native.systemFont, 36)
scoreText = display.newText( uiGroup, "Score: " .. score, 400, 80, native.systemFont, 36)

local function updateText()

  livesText.text = "Lives: " .. lives
  scoreText.text = "Score: " .. score

end

local function createAsteroid()

  local newAsteroid = display.newImageRect(mainGroup, objectSheet, 1, 102, 85)
  --> Como serão vários asteróides, aqui inserimos cada asteróide criado
  -- na tabela de asteróides "asteroidsTable"
  table.insert(asteroidsTable, newAsteroid)
	physics.addBody(newAsteroid, "dynamic", {radius=40, bounce=0.8})
	newAsteroid.myName = "asteroid"

  --> Dados três pontos de origem para os arteróides (esquerda, direita ou topo)
  -- fazemos com que essa posição seja gerada de forma randômica (entre 1 e 3)
  local whereFrom = math.random(3)

  if (whereFrom == 1) then
    --> da esquerda
    newAsteroid.x = -60 --> cria o asteróide fora do campo de visão do usuário
    newAsteroid.y = math.random(500)
    newAsteroid:setLinearVelocity(math.random(40, 120), math.random(20, 60)) --> velocidade do asteróide

  elseif ( whereFrom == 2 ) then
    --> do topo
    newAsteroid.x = math.random(display.contentWidth)
    newAsteroid.y = -60
    newAsteroid:setLinearVelocity(math.random(-40, 40), math.random(40, 120))

  elseif ( whereFrom == 3 ) then
    -- da direita
    newAsteroid.x = display.contentWidth + 60
    newAsteroid.y = math.random(500)
    newAsteroid:setLinearVelocity(math.random(-120, -40), math.random(20, 60))
  end
  --> Aplica torque para que o asteróide rotacione enquanto se move no espaço
  newAsteroid:applyTorque(math.random(-6, 6))

end

local function fireLaser()

  audio.play(gunSound, {loops = 0})
  local newLaser = display.newImageRect(mainGroup, objectSheet, 5, 14, 40)
  physics.addBody(newLaser, "dynamic", {isSensor = true})
  --> Define o laser como bala, assim o objeto vai detectar colisão continuamente
  -- garantindo que nenhum asteróide deixe de detectá-lo, já que o laser se moverá
  -- muito rápido na tela
  newLaser.isBullet = true
  newLaser.myName = "laser"

  --> Posiciona o laser com base na localização da nave
  newLaser.x = ship.x
  newLaser.y = ship.y
  --> Com essa linha de código, movemos o laser para trás da nave, porque como
  -- ele foi criado depois dela (e depende da sua posição),  por padrão ele seria
  -- posicionado à frente dela
  newLaser:toBack() --> com esse código ele ficará atrás de todo grupo "mainGroup"

  --> Comando que move o laser e recebe os parâmetros: y que indica o seu destino
  -- vertical, e o tempo que o movimento levará (em milisegundos)
  transition.to(newLaser, {y = 40, time = 500,
    --> Função callback que remove o laser da tela quando o movimento terminar
    onComplete = function() display.remove(newLaser) end
  })

end

ship:addEventListener("tap", fireLaser)

--> Função que realiza movimento da nave com base na posição do toque do usuário
local function dragShip(event)

  local ship = event.target
  --> Usado para saber em qual fase do evento de toque estamos
  -- (ex: início, movimento, fim)
  local phase = event.phase

  --> se a fase for inicial, ou seja, o usuário começou o evento de toque
  if ("began" == phase) then
    --> Seta o foco do evento de touch somente no objeto nave
    display.currentStage:setFocus(ship)
    --> Guarda a posição inicial de deslocamento
    ship.touchOffsetX = event.x - ship.x

  elseif ("moved" == phase) then
    --> Move a nave para a nova posição de toque
    ship.x = event.x - ship.touchOffsetX

  elseif ("ended" == phase or "canceled" == phase) then
    --> Retira da nave o foco do evento de toque
    display.currentStage:setFocus(nil)
  end
  --> Avisa ao Corona que o evento de toque deve terminar aqui
  return true --> Previne propagação do toque em outros objetos

end

ship:addEventListener("touch", dragShip)

--> Função que lida com a atualização das informações do jogo. Checando e
-- atualizando os objetos em tempo de execução
local function gameLoop()

  ---> Cria novo asteróide
  createAsteroid()

  --> "#asteroidsTable" retorna o tamanho da tabela asteroidsTable
  --> Esse laço (for) decrementa de um em um a tabela (-1), percorrendo do último
  -- elemento da tabela (i) até o primeiro (1).
  --> Dentro desse laço removemos asteróides deslocados pra fora da tela no jogo
  for i = #asteroidsTable, 1, -1 do
    local thisAsteroid = asteroidsTable[i]

    --> Verifica se o asteróide em questão está fora dos limites da tela
    if (thisAsteroid.x < -100 or
        thisAsteroid.x > display.contentWidth + 100 or
        thisAsteroid.y < -100 or
        thisAsteroid.y > display.contentHeight + 100)
    then
      --> se sim, remove ele da tela e da tabela
      display.remove(thisAsteroid)
      table.remove(asteroidsTable, i)
    end
  end

end

--> Define tempo para execução da função "gameLoop"
gameLoopTimer = timer.performWithDelay(500, gameLoop, 0)

--> Função chamada quando o usuário é atingido e morre fazendo a nave desaparecer
local function restoreShip()

  --> Remove a nave da simulação de física para evitar colisão até seu retorno
  ship.isBodyActive = false
  --> Reposiciona a nave no centro
  ship.x = display.contentCenterX
  ship.y = display.contentHeight - 100

  --> Reaparece com a nave aumentando sua opacidade num intervalo de 4 segundos
  transition.to(ship, {alpha = 1, time = 4000,
    onComplete = function()
      --> Transforma a nave num corpo com física novamente
      ship.isBodyActive = true
      died = false
    end
    })

end

--> Função que verifica colisão com base no momento do evento (início ou fim)
local function onCollision(event)

  --> Se uma colisão for iniciada obj1 e obj2 são referenciadas pelos objetos colidindo
  if (event.phase == "began") then
    local obj1 = event.object1
    local obj2 = event.object2

    --> Verifica qual tipo de colisão está acontecendo
    -- Se for de asteróide com laser ou vice-versa...
    if ((obj1.myName == "laser" and obj2.myName == "asteroid") or
        (obj1.myName == "asteroid" and obj2.myName == "laser"))
    then
      audio.play(explSound, {loops = 0})
      --> Remove ambos (asteróide e laser) da tela
      display.remove(obj1)
      display.remove(obj2)

      --> Remove o asteróide da lista de asteróides
      for i = #asteroidsTable, 1, -1 do
        if (asteroidsTable[i] == obj1 or asteroidsTable[i] == obj2) then
          table.remove(asteroidsTable, i)
            break --> O loop para assim que o asteróide é encontrado
        end
      end

      --> Incrementa a pontuação
      score = score + 100
      scoreText.text = "Score: " .. score

      --> "WHAT 9000? There's no way that can be right!"
      if (score == 9000) then
        OMGText = display.newText(uiGroup,
                                  "IT'S OVER 9000!!!",
                                  400, display.contentCenterY,
                                  native.systemFont, 36)
        OMGText:setFillColor(1, 0.8, 0)

      --> "I think it's right"
    elseif (score >= 10000) then
        OMGText.text = ""
      end

    --> Se for colisão de asteróide com nave ou vice-versa...
    elseif ((obj1.myName == "ship" and obj2.myName == "asteroid") or
      (obj1.myName == "asteroid" and obj2.myName == "ship"))
    then
      --> Verifica se a nave já não está morta para casos de colisões simultâneas
      -- de forma a evitar que o usuário perca mais de uma vida num mesmo momento
      if (died == false) then --> Se não estava, então seguimos o procedimento
        died = true
        --> Decrementa quantidade de vidas do usuário
        lives = lives - 1
        livesText.text = "Lives: " .. lives

        --> Verifica se o jogador já esgotou a quantidade de vidas que possui
        if (lives == 0) then
          display.remove(ship) --> Se sim, a nave é removida do jogo
          --> TODO implementar uma tela de GAME OVER
          OMGText.text = display.newText(uiGroup,
                                        "GAME OVER BRO",
                                        400, display.contentCenterY,
                                        native.systemFont, 36)
        else
          --> Se não, a nave é restaurada
          ship.alpha = 0
          timer.performWithDelay(1000, restoreShip)
        end
      end
    end
  end
end

--> Avisa ao Corona que deve procurar por colisões a cada frame do app
Runtime:addEventListener("collision", onCollision)
