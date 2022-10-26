use context essentials2021
include image
include reactors

########################################################################################
# Included images 

# https://www.saturnstudio.com/how-to-draw-a-t-rex-step-by-step-for-beginners/
T-REX = scale(0.1, image-url("https://code.pyret.org/shared-image-contents?sharedImageId=1nkeeltHq2-54nwvLR3zlVndZfwPZlUSS"))

# www.51yuansu.com/sc/eelrwkvkbd.html
METEOR = scale(0.4, image-url("https://code.pyret.org/shared-image-contents?sharedImageId=1YvZkCSpmfoxM5WK9dNmoEfo7fdcfHnVR"))

# drawn by Arnie
TRI-CEP = scale(0.08, 
  image-url("https://code.pyret.org/shared-image-contents?sharedImageId=1s1ffdH0oYTuyT0xybtiw7uYblszZHpyl"))

# UFO: https://www.flaticon.com/free-icon/ufo_3306671
# Shriram: https://cs.brown.edu/~sk/Images/me-2019-04-10-big.jpg
FLYING-SHRIRAM = scale(0.08, image-url("https://code.pyret.org/shared-image-contents?sharedImageId=1GBXZ4MQY83s25bPq1WmfYMbQnbIKO08l"))

# https://code.pyret.org/
PYRET-LOGO = scale(0.08, image-url("https://code.pyret.org/shared-image-contents?sharedImageId=1dbioFc_SHeTNS56LiGQzlFDiLcNGV_ft"))

#####################################################################################
# Datatypes

data Posn:
  | posn(x :: Number, y :: Number)
end

data Cutscene:
  | cutscene(timer :: Number, played :: Boolean)
end

data Caption:
  | caption(
      text :: String,
      font-size :: Number,
      color :: String,
      position :: Posn,
      remaining-time :: Number)
end

data Meteor:
  | meteor(
      x :: Number,
      y :: Number,
      dx :: Number,
      dy :: Number,
      flipped :: Boolean)
end

data Silly-Flipper:
  | silly-flipper(
      enabled :: Boolean,
      x :: Number,
      y :: Number,
      wave :: Number)
end

data Dinosaur-Game:
  | dinosaur-game(
      hori-speed :: Number,
      dino-height :: Number,
      dino-vertical-velocity :: Number,
      ob-hr-distance :: Number,
      flipper :: Silly-Flipper,
      cap :: List<Caption>,
      ticks-past :: Number,
      score :: Number,
      game-lost :: Boolean, 
      cts :: Cutscene,
      meteor-list :: List<Meteor>,
      display-cts :: Boolean,
      dino-hori-position :: Number)
end

########################################################################################
# Constants

CANVAS-WIDTH = 800
CANVAS-HEIGHT = 600
CANVAS = rectangle(CANVAS-WIDTH, CANVAS-HEIGHT, "solid", "light-blue")
GROUND-HEIGHT = CANVAS-HEIGHT * 9/10
GROUND-THICKNESS = CANVAS-HEIGHT * 1/5
GROUND = rectangle(CANVAS-WIDTH, GROUND-THICKNESS, "solid", "dark-slate-gray")
BG = place-image(GROUND, CANVAS-WIDTH / 2, GROUND-HEIGHT, CANVAS)

METEOR-RADIUS = image-width(METEOR) / 2
METEOR-Y-FIX = image-height(METEOR) * 0.315
METEOR-DELAY = 20
METEOR-DY = 10
METEOR-DISAPPEAR-HEIGHT = -3 * METEOR-RADIUS
SCORE-PER-METEOR = 100
METEOR-MIN-X = CANVAS-WIDTH * 0.05
METEOR-X-RANGE = CANVAS-WIDTH * 0.9

MAX-WAVE-RADIUS = 40
WAVE-EXPAND-RATE = 2

START-HORI-SPEED = 15
MAX-SPEED = 35
DINO-CENTER-SPEED = 5

RAND-OB-SPACING-BASE = 1/8 * CANVAS-WIDTH
MAX-RAND-OB-SPACING = 3
SCORE-FONT-SIZE = 20
SCORE-POSN = posn(700, 50)

DINOS-Y = 450
DINO-HORI-POS = CANVAS-WIDTH / 8
DINO-STARTING-HEIGHT = 0
GRAVITY = -7

OB-VT-DISTANCE = image-height(T-REX)

HITBOX-SHRINKER = 0.7
JUMP-VELOCITY = 60

CAPTION-SIZE = 25
CAPTION-POSN = posn(400, 200)
CAPTION-TICKS-SHORT = 60
CAPTION-TICKS-LONG = 100

TICKS-TO-CUTSCENE = 800
CUTSCENE-LENGTH = 200
SHRIRAM-Y = 100
PYRET-DOWN-TICKS = 50

POINTS-TO-WIN = 1800

########################################################################################
# Stage 2: Meteors 

fun is-colliding(game :: Dinosaur-Game) -> Boolean:
  doc: ```Return whether the player is colliding with incoming treex obstacle```
  player-right-bound = DINO-HORI-POS + (image-width(TRI-CEP) / 2)
  trex-left-bound = game.ob-hr-distance - (image-width(T-REX) / 2)
  bounds-diff = player-right-bound - trex-left-bound
  width-sum = HITBOX-SHRINKER * (image-width(T-REX) + image-width(TRI-CEP))
  if ((width-sum > bounds-diff) and (bounds-diff > 0)):
    if ((game.dino-height - (image-height(TRI-CEP) / 2)) < image-height(T-REX)):
      true
    else:
      false
    end
  else:
    false
  end

where:
  is-colliding(dinosaur-game(
      15, 
      0, 
      0, 
      625, 
      silly-flipper(false, 0, 0, 0), 
      empty, 
      25, 
      25, 
      false, 
      cutscene(200, false), 
      empty, 
      true, 
      100)) is false

  is-colliding(dinosaur-game(
      16, 
      0, 
      0, 
      187, 
      silly-flipper(false, 0, 0, 0), 
      empty, 
      53, 
      53, 
      false, 
      cutscene(200, false), 
      empty, 
      true, 
      100)) is true

  is-colliding(dinosaur-game(
      16, 
      10, 
      0, 
      150, 
      silly-flipper(false, 0, 0, 0), 
      empty, 
      53, 
      53, 
      false, 
      cutscene(200, false), 
      empty, 
      true, 
      100)) is true
end

fun purge-meteors(game :: Dinosaur-Game) -> Dinosaur-Game:
  doc: ```Remove all meteors in meteors-list in game that is above 
       METEOR-DISAPPEAR-HEIGHT.
       Add SCORE-PER-METEOR to game.score for every meteor removed```
  cases (List) game.meteor-list:
    | empty => game
    | link(met, r) =>
      purged-r = purge-meteors(
        dinosaur-game(
          game.hori-speed,
          game.dino-height,
          game.dino-vertical-velocity,
          game.ob-hr-distance,
          game.flipper,
          game.cap,
          game.ticks-past,
          game.score,
          game.game-lost,
          game.cts,
          r,
          game.display-cts,
          game.dino-hori-position))
      if (met.y < METEOR-DISAPPEAR-HEIGHT):
        dinosaur-game(
          game.hori-speed,
          game.dino-height,
          game.dino-vertical-velocity,
          game.ob-hr-distance,
          game.flipper,
          game.cap,
          game.ticks-past,
          purged-r.score + SCORE-PER-METEOR,
          game.game-lost,
          game.cts,
          purged-r.meteor-list,
          game.display-cts,
          game.dino-hori-position)
      else:
        dinosaur-game(
          game.hori-speed,
          game.dino-height,
          game.dino-vertical-velocity,
          game.ob-hr-distance,
          game.flipper,
          game.cap,
          game.ticks-past,
          purged-r.score,
          game.game-lost,
          game.cts,
          link(met, purged-r.meteor-list),
          game.display-cts,
          game.dino-hori-position)
      end
  end

where:
  game1 = dinosaur-game(
    32, 
    0, 
    0, 
    -5774, 
    silly-flipper(true, 3, 2, 12), 
    empty, 
    1169, 
    1500, 
    false, 
    cutscene(-1, true), 
    [list: meteor(141, 75.5, 0, 10, false)], 
    false,
    400)

  game2 = dinosaur-game(
    32, 
    0, 
    0, 
    -5774, 
    silly-flipper(true, 3, 2, 12), 
    empty, 
    1169, 
    1500, 
    false, 
    cutscene(-1, true), 
    [list: meteor(141, METEOR-DISAPPEAR-HEIGHT - 1, 0, 10, false)], 
    false,
    400)

  game2-expected = dinosaur-game(
    32, 
    0, 
    0, 
    -5774, 
    silly-flipper(true, 3, 2, 12), 
    empty, 
    1169, 
    1500 + SCORE-PER-METEOR, 
    false, 
    cutscene(-1, true), 
    empty, 
    false,
    400)

  game3 = dinosaur-game(
    32, 
    0, 
    0, 
    -5774, 
    silly-flipper(true, 3, 2, 12), 
    empty, 
    1169, 
    1500, 
    false, 
    cutscene(-1, true), 
    [list: meteor(141, METEOR-DISAPPEAR-HEIGHT - 1, 0, 10, false),
      meteor(25, METEOR-DISAPPEAR-HEIGHT + 1, 0, 10, false),
      meteor(562, METEOR-DISAPPEAR-HEIGHT - 10, 0, 10, false)], 
    false,
    400)

  game3-expected = dinosaur-game(
    32, 
    0, 
    0, 
    -5774, 
    silly-flipper(true, 3, 2, 12), 
    empty, 
    1169, 
    1500 + (2 * SCORE-PER-METEOR), 
    false, 
    cutscene(-1, true), 
    [list: meteor(25, METEOR-DISAPPEAR-HEIGHT + 1, 0, 10, false)], 
    false,
    400)

  purge-meteors(game1) is game1
  purge-meteors(game2) is game2-expected
  purge-meteors(game3) is game3-expected
end

#####################################################################################
# Update 

fun update(before :: Dinosaur-Game) -> Dinosaur-Game: 
  doc: "Takes in game and return game with updated fields calculated for the next tiick"
  # New-display-cts dtermins wheter it's the right time to diplay the cutscene.
  new-display-cts = (before.display-cts and 
    (before.score >= TICKS-TO-CUTSCENE)
    and (before.dino-height <= 0))
  if is-caption-on(before):
    # If caption is on, remain before and display the caption first.
    dinosaur-game(
      before.hori-speed,
      before.dino-height,
      before.dino-vertical-velocity,
      before.ob-hr-distance,
      before.flipper,
      update-caption(before.cap),
      before.ticks-past,
      before.score,
      before.game-lost,
      before.cts,
      before.meteor-list,
      before.display-cts,
      before.dino-hori-position)
  else if (before.game-lost):
    # If game lost, remain before.
    before
  else if (before.score >= POINTS-TO-WIN):
    # If game won, raise caption.
    dinosaur-game(
      before.hori-speed,
      before.dino-height,
      before.dino-vertical-velocity,
      before.ob-hr-distance,
      before.flipper,
      [list: caption("Congratulations, you saved the Jurrasaic Earth...\n", 
          CAPTION-SIZE, "brown", CAPTION-POSN, CAPTION-TICKS-LONG),
        caption("Wait, what are the humans gonna do now...?", 
          CAPTION-SIZE, "brown", CAPTION-POSN, CAPTION-TICKS-LONG)],
      before.ticks-past,
      before.score,
      true,
      before.cts,
      before.meteor-list,
      before.display-cts,
      before.dino-hori-position)
  else if (new-display-cts):
    # If it's time for cutscene, start cutscene
    dinosaur-game(
      before.hori-speed,
      before.dino-height,
      before.dino-vertical-velocity,
      before.ob-hr-distance,
      before.flipper,
      [list: caption("Oh no! Now meteors are falling which...", 
          CAPTION-SIZE, "brown", CAPTION-POSN, CAPTION-TICKS-SHORT),
        caption("...in a parallel universe...", 
          CAPTION-SIZE, "brown", CAPTION-POSN, CAPTION-TICKS-SHORT),
        caption("...once made dinosaurs go extinct!", 
          CAPTION-SIZE, "brown", CAPTION-POSN, CAPTION-TICKS-LONG),
        caption("But thankfully! Shriram is here to give u a powerful weapon!", 
          CAPTION-SIZE, "brown", CAPTION-POSN, CAPTION-TICKS-LONG)],
      before.ticks-past,
      before.score,
      false,
      cutscene(before.cts.timer, true),
      before.meteor-list,
      false,
      before.dino-hori-position)
  else if (before.cts.timer == 1):
    # If it's the last tick of the cuscene, start to move the tri-cep
    dinosaur-game(
      before.hori-speed,
      before.dino-height,
      before.dino-vertical-velocity,
      before.ob-hr-distance,
      before.flipper,
      before.cap,
      before.ticks-past,
      before.score,
      before.game-lost,
      cutscene(0, true),
      before.meteor-list,
      before.display-cts,
      before.dino-hori-position + DINO-CENTER-SPEED)
  else if (before.dino-hori-position > DINO-HORI-POS) 
    and (before.dino-hori-position < 400):
    # Moving the tri-cep to center first
    dinosaur-game(
      before.hori-speed,
      before.dino-height,
      before.dino-vertical-velocity,
      before.ob-hr-distance,
      before.flipper,
      before.cap,
      before.ticks-past,
      before.score,
      before.game-lost,
      before.cts,
      before.meteor-list,
      before.display-cts,
      before.dino-hori-position + DINO-CENTER-SPEED)
  else if (before.cts.timer == 0):
    # If cutscene is over, raise the caption and prepare for stage 2
    dinosaur-game(
      before.hori-speed,
      before.dino-height,
      before.dino-vertical-velocity,
      before.ob-hr-distance,
      before.flipper,
      [list: 
        caption("IT'S THE SILLY FLIPPER FROM LAB1!!!", 
          CAPTION-SIZE, "brown", CAPTION-POSN, CAPTION-TICKS-LONG),
        caption("Use your cursor to flip the meteors and protect your home", 
          CAPTION-SIZE, "brown", CAPTION-POSN, CAPTION-TICKS-LONG),
        caption("Ready?", 
          CAPTION-SIZE, "brown", CAPTION-POSN, CAPTION-TICKS-SHORT),
        caption("GO!", 
          CAPTION-SIZE, "brown", CAPTION-POSN, CAPTION-TICKS-SHORT)],
      before.ticks-past,
      before.score,
      false,
      cutscene(-1, true),
      before.meteor-list,
      before.display-cts,
      before.dino-hori-position)
  else if (before.cts.played and (before.cts.timer > 0)):
    # If in the middle of cutscene, freeze everything and update the cutscene.
    dinosaur-game(
      before.hori-speed,
      before.dino-height,
      before.dino-vertical-velocity,
      before.ob-hr-distance,
      before.flipper,
      update-caption(before.cap),
      before.ticks-past,
      before.score,
      before.game-lost,
      cutscene(before.cts.timer - 1, true),
      before.meteor-list,
      before.display-cts,
      before.dino-hori-position)
  else:
    # Update speed
    new-speed = num-min(MAX-SPEED, before.hori-speed + 0.1)

    # Update height with velocity
    new-height = num-max(0, before.dino-height + before.dino-vertical-velocity)

    # Update velocity with c100onstant gravity, reset to zero if hit ground
    new-velocity = if (new-height == DINO-STARTING-HEIGHT):
      0
    else:
      before.dino-vertical-velocity + GRAVITY
    end

    # Update the horizontal distance of next obstacle; if 0 spawn new obstacle (T-Rex)
    max-spawn-tick = (TICKS-TO-CUTSCENE -
      ((CANVAS-WIDTH + (RAND-OB-SPACING-BASE * MAX-RAND-OB-SPACING)) / before.hori-speed))
    new-ob-hr-distance = if (before.ob-hr-distance <= 0) and (before.display-cts) and
      (before.ticks-past <= max-spawn-tick):
      CANVAS-WIDTH + (RAND-OB-SPACING-BASE * num-random(MAX-RAND-OB-SPACING))
    else:
      before.ob-hr-distance - new-speed
    end

    # Check lose conditions
    new-game-lost = is-colliding(before) or 
    any(lam(met): (met.y + METEOR-RADIUS) > (GROUND-HEIGHT - (GROUND-THICKNESS / 2)) end,
      before.meteor-list)

    # Update caption
    new-cap = if (new-game-lost):
      [list: caption("You Lose", CAPTION-SIZE, "red", CAPTION-POSN, CAPTION-TICKS-LONG)]
    else:
      before.cap
    end
    # Update distance traveled
    new-ticks-past = before.ticks-past + 1

    # Update cutscene status
    new-cutscene = before.cts

    # Update flipper
    new-wave = if (before.flipper.wave > 0):
      before.flipper.wave - WAVE-EXPAND-RATE
    else: before.flipper.wave
    end

    new-flipper = silly-flipper(new-cutscene.played and (new-cutscene.timer <= 0),
      before.flipper.x,
      before.flipper.y,
      new-wave)

    # Add meteor to meteor-list if new-flipper.enabled is true
    added-meteor-list = if (new-flipper.enabled and 
        (num-modulo(new-ticks-past, METEOR-DELAY) == 0) and 
        (before.ob-hr-distance <= 0) and 
        (before.score <= (POINTS-TO-WIN - SCORE-PER-METEOR))):
      link(meteor(METEOR-MIN-X + num-random(METEOR-X-RANGE),
          (-1 * METEOR-RADIUS), 0, METEOR-DY, false),
        before.meteor-list)
    else:
      before.meteor-list
    end

    # Update position of meteors
    new-meteor-list = added-meteor-list.map(lam(met): if (met.flipped):
          meteor(met.x, met.y - met.dy, met.dx, met.dy, met.flipped)
        else: meteor(met.x, met.y + met.dy, met.dx, met.dy, met.flipped)
      end end)


    # Add 1 to score
    new-score = if (before.display-cts): before.score + 1 
    else: before.score end

    # Purge meteor list and add scores after updating everything
    purge-meteors(
      dinosaur-game(
        new-speed,
        new-height,
        new-velocity,
        new-ob-hr-distance,
        new-flipper,
        new-cap,
        new-ticks-past,
        new-score,
        new-game-lost,
        new-cutscene,
        new-meteor-list,
        before.display-cts,
        before.dino-hori-position))
  end

where:
  # Caption on
  update(
    dinosaur-game(
      20,
      0,
      0,
      800,
      silly-flipper(false, 10, 10, 10),
      [list: 
        caption("YOU unfortunately become a Triceratops in Jurrassic times.", 
          22, "black", posn(400, 200), 80),
        caption("Escape the T-Rex and protect your home with the help from Shriram", 
          22, "black", posn(400, 200), 100), 
        caption("First, Try using up or space to avoid the T-Rex", 22, "black", 
          posn(400, 200), 80)],
      0,
      0,
      false,
      cutscene(100, false),
      empty,
      false,
      100)) is 
  dinosaur-game(
    20,
    0,
    0,
    800,
    silly-flipper(false, 10, 10, 10),
    [list: 
      caption("YOU unfortunately become a Triceratops in Jurrassic times.", 
        22, "black", posn(400, 200), 79),
      caption("Escape the T-Rex and protect your home with the help from Shriram", 
        22, "black", posn(400, 200), 100), 
      caption("First, Try using up or space to avoid the T-Rex", 22, "black", 
        posn(400, 200), 80)],
    0,
    0,
    false,
    cutscene(100, false),
    empty,
    false,
    100)

  # Capion On: caption one less
  update(
    dinosaur-game(
      20,
      0,
      0,
      800,
      silly-flipper(false, 10, 10, 10),
      [list: 
        caption("YOU unfortunately become a Triceratops in Jurrassic times.", 
          22, "black", posn(400, 200), 0),
        caption("Escape the T-Rex and protect your home with the help from Shriram", 
          22, "black", posn(400, 200), 100), 
        caption("First, Try using up or space to avoid the T-Rex", 22, "black", 
          posn(400, 200), 80)],
      0,
      0,
      false,
      cutscene(100, false),
      empty,
      false,
      100)) is 
  dinosaur-game(
    20,
    0,
    0,
    800,
    silly-flipper(false, 10, 10, 10),
    [list: 
      caption("Escape the T-Rex and protect your home with the help from Shriram", 
        22, "black", posn(400, 200), 100), 
      caption("First, Try using up or space to avoid the T-Rex", 22, "black", 
        posn(400, 200), 80)],
    0,
    0,
    false,
    cutscene(100, false),
    empty,
    false,
    100)

  # Game lost
  update(
    dinosaur-game(
      20,
      0,
      0,
      800,
      silly-flipper(false, 10, 10, 10),
      empty,
      0,
      0,
      true,
      cutscene(100, false),
      empty,
      false,
      100)) is 
  dinosaur-game(
    20,
    0,
    0,
    800,
    silly-flipper(false, 10, 10, 10),
    empty,
    0,
    0,
    true,
    cutscene(100, false),
    empty,
    false,
    100)

  # Game Won
  update(
    dinosaur-game(
      20,
      0,
      0,
      800,
      silly-flipper(false, 10, 10, 10),
      empty,
      0,
      POINTS-TO-WIN,
      false,
      cutscene(100, false),
      empty,
      false,
      100)) is 
  dinosaur-game(
    20,
    0,
    0,
    800,
    silly-flipper(false, 10, 10, 10),
    [list: caption("Congratulations, you saved the Jurrasaic Earth...\n", 
        CAPTION-SIZE, "brown", CAPTION-POSN, CAPTION-TICKS-LONG),
      caption("Wait, what are the humans gonna do now...?", 
        CAPTION-SIZE, "brown", CAPTION-POSN, CAPTION-TICKS-LONG)],
    0,
    POINTS-TO-WIN,
    true,
    cutscene(100, false),
    empty,
    false,
    100)

  # Cutscene starts
  update(
    dinosaur-game(
      20,
      0,
      0,
      800,
      silly-flipper(false, 10, 10, 10),
      empty,
      0,
      TICKS-TO-CUTSCENE + 10,
      false,
      cutscene(100, false),
      empty,
      true,
      100)) is 
  dinosaur-game(
    20,
    0,
    0,
    800,
    silly-flipper(false, 10, 10, 10),
    [list: caption("Oh no! Now meteors are falling which...", 
        CAPTION-SIZE, "brown", CAPTION-POSN, CAPTION-TICKS-SHORT),
      caption("...in a parallel universe...", 
        CAPTION-SIZE, "brown", CAPTION-POSN, CAPTION-TICKS-SHORT),
      caption("...once made dinosaurs go extinct!", 
        CAPTION-SIZE, "brown", CAPTION-POSN, CAPTION-TICKS-LONG),
      caption("But thankfully! Shriram is here to give u a powerful weapon!", 
        CAPTION-SIZE, "brown", CAPTION-POSN, CAPTION-TICKS-LONG)],
    0,
    TICKS-TO-CUTSCENE + 10,
    false,
    cutscene(100, true),
    empty,
    false,
    100)

  # TRI-CEP moves
  update(
    dinosaur-game(
      20,
      0,
      0,
      800,
      silly-flipper(false, 10, 10, 10),
      empty,
      0,
      TICKS-TO-CUTSCENE + 10,
      false,
      cutscene(1, true),
      empty,
      false,
      100)) is 
  dinosaur-game(
    20,
    0,
    0,
    800,
    silly-flipper(false, 10, 10, 10),
    empty,
    0,
    TICKS-TO-CUTSCENE + 10,
    false,
    cutscene(0, true),
    empty,
    false,
    105)

  # TRI-CEP moving
  update(dinosaur-game(
      20,
      0,
      0,
      800,
      silly-flipper(false, 10, 10, 10),
      empty,
      0,
      TICKS-TO-CUTSCENE + 10,
      false,
      cutscene(0, true),
      empty,
      false,
      105)) is 
  dinosaur-game(
    20,
    0,
    0,
    800,
    silly-flipper(false, 10, 10, 10),
    empty,
    0,
    TICKS-TO-CUTSCENE + 10,
    false,
    cutscene(0, true),
    empty,
    false,
    110)

  # cutscene ends
  update(dinosaur-game(
      20,
      0,
      0,
      800,
      silly-flipper(false, 10, 10, 10),
      empty,
      0,
      TICKS-TO-CUTSCENE + 10,
      false,
      cutscene(0, true),
      empty,
      false,
      400)) is 
  dinosaur-game(
    20,
    0,
    0,
    800,
    silly-flipper(false, 10, 10, 10),
    [list: 
      caption("IT'S THE SILLY FLIPPER FROM LAB1!!!", 
        CAPTION-SIZE, "brown", CAPTION-POSN, CAPTION-TICKS-LONG),
      caption("Use your cursor to flip the meteors and protect your home", 
        CAPTION-SIZE, "brown", CAPTION-POSN, CAPTION-TICKS-LONG),
      caption("Ready?", 
        CAPTION-SIZE, "brown", CAPTION-POSN, CAPTION-TICKS-SHORT),
      caption("GO!", 
        CAPTION-SIZE, "brown", CAPTION-POSN, CAPTION-TICKS-SHORT)],
    0,
    TICKS-TO-CUTSCENE + 10,
    false,
    cutscene(-1, true),
    empty,
    false,
    400)

  # Cutscene going on
  update(dinosaur-game(
      20,
      0,
      0,
      800,
      silly-flipper(false, 10, 10, 10),
      empty,
      0,
      TICKS-TO-CUTSCENE + 10,
      false,
      cutscene(10, true),
      empty,
      false,
      100)) is 
  dinosaur-game(
    20,
    0,
    0,
    800,
    silly-flipper(false, 10, 10, 10),
    empty,
    0,
    TICKS-TO-CUTSCENE + 10,
    false,
    cutscene(9, true),
    empty,
    false,
    100)

  # Check lose condition & update caption
  update(
    dinosaur-game(
      16, 
      0, 
      0, 
      182, 
      silly-flipper(false, 0, 0, 0), 
      empty, 
      104, 
      104, 
      false,
      cutscene(200, false), 
      [list: ], true, 100)) is
  dinosaur-game(
    16.1,
    0, 
    0, 
    165.9, 
    silly-flipper(false, 0, 0, 0), 
    [list: caption("You Lose", 25, "red", posn(400, 200), 100)],
    105, 
    105,
    true, 
    cutscene(200, false),
    [list: ], 
    true, 
    100)

  # Update speed, height, velocity
  is-spawning(update(dinosaur-game(
        20,
        10,
        10,
        800,
        silly-flipper(false, 10, 10, 10),
        empty,
        0,
        TICKS-TO-CUTSCENE + 10,
        false,
        cutscene(-1, true),
        empty,
        false,
        100))) is false

  is-spawning(update(dinosaur-game(
        20,
        0,
        100,
        800,
        silly-flipper(false, 10, 10, 10),
        empty,
        0,
        TICKS-TO-CUTSCENE + 10,
        false,
        cutscene(-1, true),
        empty,
        false,
        100))) is false

  # Property-based test on spawn
  is-spawning(update(dinosaur-game(
        20,
        10,
        10,
        0,
        silly-flipper(false, 10, 10, 10),
        empty,
        0,
        TICKS-TO-CUTSCENE + 10,
        false,
        cutscene(-1, true),
        empty,
        true,
        100))) is true 
  is-spawning(update(dinosaur-game(
        20,
        10,
        10,
        -100,
        silly-flipper(false, 10, 10, 10),
        empty,
        0,
        TICKS-TO-CUTSCENE + 10,
        false,
        cutscene(-1, true),
        empty,
        true,
        100))) is true

  # Flipper wave update
  update(dinosaur-game(
      20,
      0,
      0,
      -100,
      silly-flipper(true, 10, 10, 10),
      empty,
      1001,
      1001,
      false,
      cutscene(-1, true),
      [list: ],
      false,
      400)).flipper.wave is 10 - WAVE-EXPAND-RATE

  # Meteor is created when conditions are met
  update(dinosaur-game(
      25,
      0,
      0,
      -1000,
      silly-flipper(true, 123, 7, 0),
      empty,
      1019,
      1019,
      false,
      cutscene(-1, true),
      [list: ],
      false,
      400)).meteor-list is-not empty

  # Meteor is updated
  update(dinosaur-game(
      25,
      0,
      0,
      -1000,
      silly-flipper(true, 123, 7, 0),
      empty,
      1021,
      1021,
      false,
      cutscene(-1, true),
      [list: meteor(460, -14.5, 0, 10, false)],
      false,
      400)).meteor-list is [list: meteor(460, -4.5, 0, 10, false)]
end

#####################################################################################
# Property-based test function

fun is-spawning(game :: Dinosaur-Game) -> Boolean:
  doc: ``` Returns if a game is properly spawning new obstacles```
  (game.ob-hr-distance >= 800) and
  (game.ob-hr-distance <= 1100)

where:
  is-spawning(dinosaur-game(
      20,
      10,
      10,
      900,
      silly-flipper(false, 10, 10, 10),
      empty,
      0,
      TICKS-TO-CUTSCENE + 10,
      false,
      cutscene(-1, true),
      empty,
      true,
      100)) is true
  is-spawning(dinosaur-game(
      20,
      10,
      10,
      1100,
      silly-flipper(false, 10, 10, 10),
      empty,
      0,
      TICKS-TO-CUTSCENE + 10,
      false,
      cutscene(-1, true),
      empty,
      true,
      100)) is true
end

#####################################################################################
# Key and Mouse 

fun key-pressed(game :: Dinosaur-Game, key :: String) -> Dinosaur-Game:
  doc: ```When space or up button is pressed,
       update vertical velocity of player in game to JUMP-VELOCITY```
  if ( ((key == " ") or (key == "up")) and (game.dino-height == 0)):
    dinosaur-game(
      game.hori-speed,
      game.dino-height,
      JUMP-VELOCITY,
      game.ob-hr-distance,
      game.flipper,
      game.cap,
      game.ticks-past,
      game.score,
      game.game-lost,
      game.cts,
      game.meteor-list,
      game.display-cts,
      game.dino-hori-position)
  else:
    game
  end

where:
  # Legal Jump
  key-pressed(
    dinosaur-game(
      20,
      0,
      0,
      300,
      silly-flipper(true, 10, 10, 10),
      empty,
      2000,
      1000,
      false,
      cutscene(100, false),
      empty,
      true,
      100), " ") is
  dinosaur-game(
    20,
    0,
    JUMP-VELOCITY,
    300,
    silly-flipper(true, 10, 10, 10),
    empty,
    2000,
    1000,
    false,
    cutscene(100, false),
    empty,
    true,
    100)

  # Legal Jump
  key-pressed(
    dinosaur-game(
      20,
      0,
      100,
      300,
      silly-flipper(true, 10, 10, 10),
      empty,
      2000,
      1000,
      false,
      cutscene(100, false),
      empty,
      true,
      100), " ") is 
  dinosaur-game(
    20,
    0,
    JUMP-VELOCITY,
    300,
    silly-flipper(true, 10, 10, 10),
    empty,
    2000,
    1000,
    false,
    cutscene(100, false),
    empty,
    true,
    100)

  # Illegal Jump
  key-pressed(
    dinosaur-game(
      20,
      20,
      100,
      300,
      silly-flipper(true, 10, 10, 10),
      empty,
      2000,
      1000,
      false,
      cutscene(100, false),
      empty,
      true,
      100), " ") is
  dinosaur-game(
    20,
    20,
    100,
    300,
    silly-flipper(true, 10, 10, 10),
    empty,
    2000,
    1000,
    false,
    cutscene(100, false),
    empty,
    true,
    100)

  # Illegal Jump
  key-pressed(
    dinosaur-game(
      20,
      100,
      100,
      300,
      silly-flipper(true, 10, 10, 10),
      empty,
      2000,
      1000,
      false,
      cutscene(100, false),
      empty,
      true,
      100), " ") is
  dinosaur-game(
    20,
    100,
    100,
    300,
    silly-flipper(true, 10, 10, 10),
    empty,
    2000,
    1000,
    false,
    cutscene(100, false),
    empty,
    true,
    100)
end

fun mouse-action(game :: Dinosaur-Game, mouse-x :: Number,
    mouse-y :: Number, action-type :: String) -> Dinosaur-Game:
  doc: ```Update values of game.flipper to reflect player mouse movement and click;
       flip meteors clicked by mouse```
  if (game.flipper.enabled):
    ask:
      | action-type == "button-down" then:
        new-flipper = silly-flipper(true, mouse-x, mouse-y, MAX-WAVE-RADIUS)
        new-meteor-list = game.meteor-list.map(lam(met):
            clicked = (num-abs(mouse-x - met.x) < METEOR-RADIUS) and
            (num-abs(mouse-y - (met.y + METEOR-Y-FIX)) < METEOR-RADIUS)
            if (clicked): meteor(met.x, met.y, met.dx, met.dy, not(met.flipped))
          else: met end end)
        dinosaur-game(
          game.hori-speed,
          game.dino-height,
          game.dino-vertical-velocity,
          game.ob-hr-distance,
          new-flipper,
          game.cap,
          game.ticks-past,
          game.score,
          game.game-lost,
          game.cts,
          new-meteor-list,
          game.display-cts,
          game.dino-hori-position)
      | action-type == "move" then:
        new-flipper = silly-flipper(true, mouse-x, mouse-y, game.flipper.wave)
        dinosaur-game(
          game.hori-speed,
          game.dino-height,
          game.dino-vertical-velocity,
          game.ob-hr-distance,
          new-flipper,
          game.cap,
          game.ticks-past,
          game.score,
          game.game-lost,
          game.cts,
          game.meteor-list,
          game.display-cts,
          game.dino-hori-position)
      | otherwise: game
    end
  else: game
  end

where:
  # Button down and on-target 
  mouse-action(
    dinosaur-game(
      20,
      0,
      0,
      0,
      silly-flipper(true, 0, 0, 0),
      empty,
      0,
      10,
      false,
      cutscene(0, false),
      [list: meteor(1, 1 - (image-height(METEOR) * 0.315), 1, 1, false)],
      false,
      100), 1, 1, "button-down") is 
  dinosaur-game(
    20,
    0,
    0,
    0,
    silly-flipper(true, 1, 1, MAX-WAVE-RADIUS),
    empty,
    0,
    10,
    false,
    cutscene(0, false),
    [list: meteor(1, 1 - (image-height(METEOR) * 0.315), 1, 1, true)],
    false,
    100)

  # Button down and on-target: in radius 
  mouse-action(
    dinosaur-game(
      20,
      0,
      0,
      0,
      silly-flipper(true, 0, 0, 0),
      empty,
      0,
      10,
      false,
      cutscene(0, false),
      [list: meteor(1, 2 - METEOR-RADIUS - (image-height(METEOR) * 0.315), 1, 1, false)],
      false,
      100), 1, 1, "button-down") is 
  dinosaur-game(
    20,
    0,
    0,
    0,
    silly-flipper(true, 1, 1, MAX-WAVE-RADIUS),
    empty,
    0,
    10,
    false,
    cutscene(0, false),
    [list: meteor(1, 2 - METEOR-RADIUS - (image-height(METEOR) * 0.315), 1, 1, true)],
    false,
    100)

  # Button down and not-clicked 
  mouse-action(
    dinosaur-game(
      20,
      0,
      0,
      0,
      silly-flipper(true, 0, 0, 0),
      empty,
      0,
      10,
      false,
      cutscene(0, false),
      [list: meteor(1, 1, 1, 1, false)],
      false,
      100), 1, 1, "button-down") is 
  dinosaur-game(
    20,
    0,
    0,
    0,
    silly-flipper(true, 1, 1, MAX-WAVE-RADIUS),
    empty,
    0,
    10,
    false,
    cutscene(0, false),
    [list: meteor(1, 1, 1, 1, false)],
    false,
    100)

  # Move 
  mouse-action(
    dinosaur-game(
      20,
      0,
      0,
      0,
      silly-flipper(true, 0, 0, 0),
      empty,
      0,
      10,
      false,
      cutscene(0, false),
      [list: meteor(1, 0 - (image-height(METEOR) * 0.315), 1, 1, false)],
      false,
      100), 1, 1, "move") is 
  dinosaur-game(
    20,
    0,
    0,
    0,
    silly-flipper(true, 1, 1, 0),
    empty,
    0,
    10,
    false,
    cutscene(0, false),
    [list: meteor(1, 0 - (image-height(METEOR) * 0.315), 1, 1, false)],
    false,
    100)

  # game-flipper not enabled  
  mouse-action(
    dinosaur-game(
      20,
      0,
      0,
      0,
      silly-flipper(false, 0, 0, 0),
      empty,
      0,
      10,
      false,
      cutscene(0, false),
      [list: meteor(1, 0 - (image-height(METEOR) * 0.315), 1, 1, false)],
      false,
      100), 1, 1, "button-down") is 
  dinosaur-game(
    20,
    0,
    0,
    0,
    silly-flipper(false, 0, 0, 0),
    empty,
    0,
    10,
    false,
    cutscene(0, false),
    [list: meteor(1, 0 - (image-height(METEOR) * 0.315), 1, 1, false)],
    false,
    100)
end

#####################################################################################
# Caption

fun is-caption-on(game :: Dinosaur-Game) -> Boolean:
  doc: "Returns whether cap field of game is empty"
  not(game.cap == empty)

where:
  is-caption-on(dinosaur-game(
      20,
      0,
      0,
      300,
      silly-flipper(true, 10, 10, 10),
      empty,
      2000,
      1000,
      false,
      cutscene(100, false),
      empty,
      true,
      100)) is false
  is-caption-on(dinosaur-game(
      20,
      0,
      0,
      300,
      silly-flipper(true, 10, 10, 10),
      [list: 
        caption("YOU unfortunately become a Triceratops in Jurrassic times.", 
          22, "black", posn(400, 200), 80),
        caption("Escape the T-Rex and protect your home with the help from Shriram", 
          22, "black", posn(400, 200), 100), 
        caption("First, Try using up or space to avoid the T-Rex", 22, "black", 
          posn(400, 200), 80)],
      2000,
      1000,
      false,
      cutscene(100, false),
      empty,
      true,
      100)) is true
end

fun update-caption(loc :: List<Caption>) -> List<Caption>:
  doc: ```Reduce time of first item in loc by 1, 
       remove it from loc if its timer reach 0.
       Returns empty for empty input```
  cases (List)loc:
    | empty => empty
    | link(f,r) =>
      if (f.remaining-time == 0): r
      else: 
        new-caption = caption(f.text, f.font-size, f.color, f.position, 
          f.remaining-time - 1)
        link(new-caption, r)
      end
  end

where:
  # Caption is empty
  update-caption(empty) is empty 

  # Caption.first.remain-time > 0
  update-caption( [list: 
      caption("YOU unfortunately become a Triceratops in Jurrassic times.", 
        22, "black", posn(400, 200), 80),
      caption("Escape the T-Rex and protect your home with the help from Shriram", 
        22, "black", posn(400, 200), 100), 
      caption("First, Try using up or space to avoid the T-Rex", 22, "black", 
        posn(400, 200), 80)]) is 
  [list: 
    caption("YOU unfortunately become a Triceratops in Jurrassic times.", 
      22, "black", posn(400, 200), 79),
    caption("Escape the T-Rex and protect your home with the help from Shriram", 
      22, "black", posn(400, 200), 100), 
    caption("First, Try using up or space to avoid the T-Rex", 22, "black", 
      posn(400, 200), 80)]

  # Caption.first.remaining-time == 0
  update-caption( [list: 
      caption("YOU unfortunately become a Triceratops in Jurrassic times.", 
        22, "black", posn(400, 200), 0),
      caption("Escape the T-Rex and protect your home with the help from Shriram", 
        22, "black", posn(400, 200), 100), 
      caption("First, Try using up or space to avoid the T-Rex", 22, "black", 
        posn(400, 200), 80)]) is 
  [list: 
    caption("Escape the T-Rex and protect your home with the help from Shriram", 
      22, "black", posn(400, 200), 100), 
    caption("First, Try using up or space to avoid the T-Rex", 22, "black", 
      posn(400, 200), 80)]
end 

fun stop(game :: Dinosaur-Game) -> Boolean:
  doc: ``` Close the game when caption is off and game is lost or won.```
  game.game-lost and not(is-caption-on(game))

where:
  # When game is on and caption is on, false
  stop(dinosaur-game(
      20,
      100,
      100,
      300,
      silly-flipper(true, 10, 10, 10),
      [list: caption("", 1, "", posn(1,1), 1)],
      2000,
      1000,
      false,
      cutscene(100, false),
      empty,
      true,
      100)) is false

  # When game is on and caption is off, false
  stop(dinosaur-game(
      20,
      100,
      100,
      300,
      silly-flipper(true, 10, 10, 10),
      empty,
      2000,
      1000,
      false,
      cutscene(100, false),
      empty,
      true,
      100)) is false

  # When game is off and caption is on, false
  stop(dinosaur-game(
      20,
      100,
      100,
      300,
      silly-flipper(true, 10, 10, 10),
      [list: caption("", 1, "", posn(1,1), 1)],
      2000,
      1000,
      true,
      cutscene(100, false),
      empty,
      true,
      100)) is false

  # When game is off and caption is off, true
  stop(dinosaur-game(
      20,
      100,
      100,
      300,
      silly-flipper(true, 10, 10, 10),
      [list: caption("", 1, "", posn(1,1), 1)],
      2000,
      1000,
      true,
      cutscene(100, false),
      empty,
      true,
      100)) is false
end

#####################################################################################
# Draw dino game

fun draw-dino-game(game :: Dinosaur-Game) -> Image:
  doc: ```Draw the game screen shown to players given a Dinosaur-Game.
       Add each item sequentially on top of the last```

  # Draw player on background
  tri-and-bg = place-image(TRI-CEP, game.dino-hori-position, 
    DINOS-Y - game.dino-height, BG)

  # Draw obstacle (T-REX) on previous result
  ob-tri-and-bg = place-image(T-REX, game.ob-hr-distance, DINOS-Y, tri-and-bg)

  # Draw current score on previous result
  ob-tri-bg-score = place-image(text("Score: " + num-to-string(game.score),
      SCORE-FONT-SIZE,
      "black"), SCORE-POSN.x, SCORE-POSN.y, ob-tri-and-bg)

  # Draw cutscene, if it currently going, on previous result
  cutscene-added = ask:
    | game.cts.played and (game.cts.timer > PYRET-DOWN-TICKS) then:
      place-image(FLYING-SHRIRAM,
        DINO-HORI-POS + (CANVAS-WIDTH * 
          (((game.cts.timer + 1) - PYRET-DOWN-TICKS) / (CUTSCENE-LENGTH - PYRET-DOWN-TICKS))),
        SHRIRAM-Y, ob-tri-bg-score)
    | game.cts.played and (game.cts.timer > 0) then:
      place-image(
        PYRET-LOGO,
        DINO-HORI-POS,
        SHRIRAM-Y +
        (((PYRET-DOWN-TICKS - game.cts.timer) / PYRET-DOWN-TICKS) * (DINOS-Y - SHRIRAM-Y)),
        place-image(FLYING-SHRIRAM,
          DINO-HORI-POS,
          SHRIRAM-Y, ob-tri-bg-score))
    | otherwise:
      ob-tri-bg-score
  end

  # Draw meteors in meteor-list of game on previous result
  meteor-added = game.meteor-list.foldl(lam(met, img): 
      met-pic = if (met.flipped): rotate(180, METEOR)
      else: METEOR end
    place-image(met-pic, met.x, met.y, img) end, cutscene-added)

  # Draw cursor on previous result
  cursor-added = if (game.flipper.enabled):
    place-image(PYRET-LOGO, game.flipper.x, game.flipper.y, meteor-added)
  else:
    meteor-added
  end

  # Draw wave from clicking around cursor on previous result
  wave-added = if (not(game.flipper.wave == 0) and game.flipper.enabled):
    place-image(circle(MAX-WAVE-RADIUS - game.flipper.wave, "outline", "blue"),
      game.flipper.x, game.flipper.y, cursor-added)
  else: cursor-added
  end

  # Draw caption on previous result, if captions are on
  if (is-caption-on(game)):
    f = game.cap.first
    place-image(text(f.text, f.font-size, f.color),
      f.position.x, f.position.y, wave-added)
  else:
    wave-added
  end

where:
  drawn-image = draw-dino-game(dinosaur-game(
      START-HORI-SPEED,
      DINO-STARTING-HEIGHT,
      0,
      -100,
      silly-flipper(true, 0, 0, 0),
      empty,
      TICKS-TO-CUTSCENE + 200,
      TICKS-TO-CUTSCENE + 200,
      false,
      cutscene(-1, true),
      [list:],
      false,
      CANVAS-WIDTH / 2))
  image-width(drawn-image) is CANVAS-WIDTH
  image-height(drawn-image) is CANVAS-HEIGHT
end

#####################################################################################
# Reactor & Tests

r = reactor:
  init: dinosaur-game(
      START-HORI-SPEED,
      DINO-STARTING-HEIGHT,
      0,
      1000,
      silly-flipper(false, 0, 0, 0),
      [list: 
        caption("You unfortunately became a Triceratops in Jurrassic times.", 
          CAPTION-SIZE, "black", CAPTION-POSN, CAPTION-TICKS-SHORT),
        caption("Escape coming T-Rex and protect your home with the help from Shriram", 
          CAPTION-SIZE, "black", CAPTION-POSN, CAPTION-TICKS-LONG), 
        caption("First, jump with up/space keys to avoid the T-Rex", CAPTION-SIZE, "black", 
          CAPTION-POSN, CAPTION-TICKS-LONG)],
      0,
      0,
      false,
      cutscene(CUTSCENE-LENGTH, false),
      [list:],
      true,
      DINO-HORI-POS),
  on-key: key-pressed,
  on-tick: update,
  to-draw: draw-dino-game,
  on-mouse: mouse-action,
  stop-when: stop,
  close-when-stop: true
end

interact(r)

testing-reactor-num = reactor:
  init: 0,
  on-tick: lam(x): x + 1 end
end

testing-reactor-lst = reactor:
  init: empty,
  on-tick: lam(x): link("a", x) end
end

fun react-n-ticks<A>(rea :: Reactor<A>, n :: Number):
  doc: "Return r after n ticks of no user input"
  ask:
    | n == 0 then: rea
    | otherwise: react(react-n-ticks(rea, n - 1), time-tick)
  end
where:
  get-value(react-n-ticks(testing-reactor-num, 0)) is 0
  get-value(react-n-ticks(testing-reactor-num, 5)) is 5
  get-value(react-n-ticks(testing-reactor-lst, 0)) is empty
  get-value(react-n-ticks(testing-reactor-lst, 1)) is [list: "a"]
  get-value(react-n-ticks(testing-reactor-lst, 10)) is repeat(10, "a")
end

check "Captions are correctly removed after set amount of time":
  get-value(react-n-ticks(r, 270)).cap is empty
end

check "Without any player action, loses after 500 ticks":
  get-value(react-n-ticks(r, 500)).game-lost is true
end

check "Meteors spawn after getting flipper":
  temp-reactor = reactor:
    init: dinosaur-game(
        START-HORI-SPEED,
        DINO-STARTING-HEIGHT,
        0,
        -100,
        silly-flipper(true, 0, 0, 0),
        empty,
        TICKS-TO-CUTSCENE + 200,
        TICKS-TO-CUTSCENE + 200,
        false,
        cutscene(-1, true),
        [list:],
        false,
        CANVAS-WIDTH / 2),
    on-key: key-pressed,
    on-tick: update,
    to-draw: draw-dino-game,
    on-mouse: mouse-action,
    stop-when: stop,
    close-when-stop: true
  end
  get-value(react-n-ticks(temp-reactor, 50)).meteor-list is-not empty
end

check "Captions are displayed when cutscene starts":
  temp-reactor = reactor:
    init: dinosaur-game(
        START-HORI-SPEED,
        DINO-STARTING-HEIGHT,
        0,
        1000,
        silly-flipper(false, 0, 0, 0),
        empty,
        TICKS-TO-CUTSCENE + 1,
        TICKS-TO-CUTSCENE + 1,
        false,
        cutscene(CUTSCENE-LENGTH, false),
        [list:],
        true,
        CANVAS-WIDTH / 2),
    on-key: key-pressed,
    on-tick: update,
    to-draw: draw-dino-game,
    on-mouse: mouse-action,
    stop-when: stop,
    close-when-stop: true
  end
  get-value(react-n-ticks(temp-reactor, 1)).cap
    is [list: caption("Oh no! Now meteors are falling which...", 
      CAPTION-SIZE, "brown", CAPTION-POSN, CAPTION-TICKS-SHORT),
    caption("...in a parallel universe...", 
      CAPTION-SIZE, "brown", CAPTION-POSN, CAPTION-TICKS-SHORT),
    caption("...once made dinosaurs go extinct!", 
      CAPTION-SIZE, "brown", CAPTION-POSN, CAPTION-TICKS-LONG),
    caption("But thankfully! Shriram is here to give u a powerful weapon!", 
      CAPTION-SIZE, "brown", CAPTION-POSN, CAPTION-TICKS-LONG)]
end

check "Letting meteors fall without intervention will lose the game":
  temp-reactor = reactor:
    init: dinosaur-game(
        START-HORI-SPEED,
        DINO-STARTING-HEIGHT,
        0,
        1000,
        silly-flipper(true, 0, 0, 0),
        empty,
        TICKS-TO-CUTSCENE + 1,
        0,
        false,
        cutscene(-1, true),
        [list:],
        false,
        CANVAS-WIDTH / 2),
    on-key: key-pressed,
    on-tick: update,
    to-draw: draw-dino-game,
    on-mouse: mouse-action,
    stop-when: stop,
    close-when-stop: true
  end
  get-value(react-n-ticks(temp-reactor, 200)).game-lost is true
end

check "Lost game stops being updated":
  temp-reactor = reactor:
    init: dinosaur-game(
        START-HORI-SPEED,
        DINO-STARTING-HEIGHT,
        0,
        1000,
        silly-flipper(false, 0, 0, 0),
        empty,
        0,
        0,
        true,
        cutscene(CUTSCENE-LENGTH, false),
        [list:],
        true,
        DINO-HORI-POS),
    on-key: key-pressed,
    on-tick: update,
    to-draw: draw-dino-game,
    on-mouse: mouse-action,
    stop-when: stop,
    close-when-stop: true
  end
  react-n-ticks(temp-reactor, 5000) is temp-reactor
end

check "Won game displays captions":
  temp-reactor = reactor:
    init: dinosaur-game(
        START-HORI-SPEED,
        DINO-STARTING-HEIGHT,
        0,
        1000,
        silly-flipper(false, 0, 0, 0),
        empty,
        1000000000000000,
        1000000000000000,
        false,
        cutscene(CUTSCENE-LENGTH, false),
        [list:],
        true,
        DINO-HORI-POS),
    on-key: key-pressed,
    on-tick: update,
    to-draw: draw-dino-game,
    on-mouse: mouse-action,
    stop-when: stop,
    close-when-stop: true
  end
  get-value(react-n-ticks(temp-reactor, 1)).cap
    is [list: caption("Congratulations, you saved the Jurrasaic Earth...\n", 
      CAPTION-SIZE, "brown", CAPTION-POSN, CAPTION-TICKS-LONG),
    caption("Wait, what are the humans gonna do now...?", 
      CAPTION-SIZE, "brown", CAPTION-POSN, CAPTION-TICKS-LONG)]
end

check "Won game all captions removed after wset amount of time":
  temp-reactor = reactor:
    init: dinosaur-game(
        START-HORI-SPEED,
        DINO-STARTING-HEIGHT,
        0,
        1000,
        silly-flipper(false, 0, 0, 0),
        empty,
        1000000000000000,
        1000000000000000,
        false,
        cutscene(CUTSCENE-LENGTH, false),
        [list:],
        true,
        DINO-HORI-POS),
    on-key: key-pressed,
    on-tick: update,
    to-draw: draw-dino-game,
    on-mouse: mouse-action,
    stop-when: stop,
    close-when-stop: true
  end
  get-value(react-n-ticks(temp-reactor, 203)).cap is empty
end
