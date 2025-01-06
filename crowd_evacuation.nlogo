globals [
  blue-escapees
  cyan-escapees
  yellow-escapees
  red-escapees
  beige-escapees
  green-escapees
  blue-fire-deaths
  cyan-fire-deaths
  yellow-fire-deaths
  red-fire-deaths
  beige-fire-deaths
  green-fire-deaths
  blue-stampede-deaths
  cyan-stampede-deaths
  yellow-stampede-deaths
  red-stampede-deaths
  beige-stampede-deaths
  green-stampede-deaths
  female-escapees
  female-fire-deaths
  female-stampede-deaths
  male-escapees
  male-fire-deaths
  male-stampede-deaths
  child-escapees
  child-fire-deaths
  child-stampede-deaths
  adult-escapees
  adult-fire-deaths
  adult-stampede-deaths
  elderly-escapees
  elderly-fire-deaths
  elderly-stampede-deaths
  oldgoal
]
breed [survivors survivor]
breed[doors door]
patches-own [
  distance1
  distance2
  distance3
  distance4
  distance5
  distance6
  distance7
  distance8
  distance9
  distance10
  distancefire
]

survivors-own [
  goal
  health
  base-speed
  speed  ; impacted by status and patch pressure (sum surrounding patch pressure)
  vision
  gender
  age
  mass
  panic
;  reaction-time
;  collaboration
;  insistence
  knowledge
]

to setup
  ca
  setup-stadium
  ;create 10 exits
  let door-xlist [-127 -87 -70 -49 -33 27 44 65 82 122]
  (foreach door-xlist[ [x] ->
     create-doors 1 [setxy x 21 set shape "square" set color lime set heading 180 set size 2]
    ])

  ask patches [set distance1 [distance myself] of door 14178]
  ask patches [set distance2 [distance myself] of door 14179]
  ask patches [set distance3 [distance myself] of door 14180]
  ask patches [set distance4 [distance myself] of door 14181]
  ask patches [set distance5 [distance myself] of door 14182]
  ask patches [set distance6 [distance myself] of door 14183]
  ask patches [set distance7 [distance myself] of door 14184]
  ask patches [set distance8 [distance myself] of door 14185]
  ask patches [set distance9 [distance myself] of door 14186]
  ask patches [set distance10 [distance myself] of door 14187]
  ;set goal
  ask survivors[
    set goal min-one-of doors [distance myself]
  ]
  set-survivors-attributes
  ; Start fire
  let origin patch 0 135
  if random-fire? [
    set origin patch random-xcor random-ycor
    while [ [ pcolor ] of origin = black ] [
      set origin one-of patches
    ]
  ]
  ask origin [
    draw-rectangle pxcor pycor 5 5 orange
  ]
  ask patches [set distancefire distancexy 0 135]

  reset-ticks
end

to go
  spread-fire
  ;ask patches [set distancefire min [distance myself] of patches with  [pcolor = orange]]
  if use-panic? [
    ask survivors [
      if is-patch? patch-at-heading-and-distance (180 + heading) vision [
        if [pcolor] of patch-ahead vision = orange or [pcolor] of patch-at-heading-and-distance (180 + heading) vision = orange [
          set panic 2
          set speed 1.8056 ; 6.5km/h = 1.8056m/s
        ]
      ]

      if is-patch? patch-at-heading-and-distance (180 + heading) (vision / 2) [
        if [pcolor] of patch-ahead (vision / 2) = orange or [pcolor] of patch-at-heading-and-distance (180 + heading) (vision / 2) = orange [
          set panic 3
          set speed 2.5 ; 9km/h = 2.5m/s
        ]
      ]

      ;    set speed base-speed * panic
    ]
  ]

  ifelse behaviour = "smart"
  [ move-normal ]
  [ follow-crowd ]

  ; Compute force exerted by survivors on each patch
  ask survivors [
    if compute-force patch-here >= health [
      ifelse color = blue
      [ set blue-stampede-deaths blue-stampede-deaths + 1]
      [ ifelse color = cyan
        [ set cyan-stampede-deaths cyan-stampede-deaths + 1 ]
        [ ifelse color = yellow
          [ set yellow-stampede-deaths yellow-stampede-deaths + 1 ]
          [ ifelse color = red
            [ set red-stampede-deaths red-stampede-deaths + 1 ]
            [ ifelse color = 29
              [ set beige-stampede-deaths beige-stampede-deaths + 1 ]
              [ set green-stampede-deaths green-stampede-deaths + 1 ]
            ]
          ]
        ]
      ]

      ifelse gender = "female"
      [ set female-stampede-deaths female-stampede-deaths + 1 ]
      [ set male-stampede-deaths male-stampede-deaths + 1 ]

      ifelse age = "child"
      [ set child-stampede-deaths child-stampede-deaths + 1 ]
      [ ifelse age = "adult"
        [ set adult-stampede-deaths adult-stampede-deaths + 1 ]
        [ set elderly-stampede-deaths elderly-stampede-deaths + 1 ]
      ]

      die
    ]
  ]

  tick
end

to-report compute-force [ p ]
  ; Force exerted by survivors in the patch
  ; acceleration = (vFinal−vInitial)/(tFinal−tInitial)
  ; Force = mass x acceleration
  let force 0
  ask survivors-on p [
    set force force + mass * speed
  ]
  report force
end

to spread-fire
  ; Fire expands every 2 seconds
  if ticks mod 10 = 0 [
    ask patches with [ pcolor = orange ] [
      ask neighbors with [ pcolor != black ] [
        set pcolor orange
      ]
    ]
  ]

  ask survivors [
    ;; Kill survivors on patches which have caught fire
    if [ pcolor ] of patch-here = orange [
      ifelse color = blue
      [ set blue-fire-deaths blue-fire-deaths + 1]
      [ ifelse color = cyan
        [ set cyan-fire-deaths cyan-fire-deaths + 1 ]
        [ ifelse color = yellow
          [ set yellow-fire-deaths yellow-fire-deaths + 1 ]
          [ ifelse color = red
            [ set red-fire-deaths red-fire-deaths + 1 ]
            [ ifelse color = 29
              [ set beige-fire-deaths beige-fire-deaths + 1 ]
              [ set green-fire-deaths green-fire-deaths + 1 ]
            ]
          ]
        ]
      ]

      ifelse gender = "female"
      [ set female-fire-deaths female-fire-deaths + 1 ]
      [ set male-fire-deaths male-fire-deaths + 1 ]

      ifelse age = "child"
      [ set child-fire-deaths child-fire-deaths + 1 ]
      [ ifelse age = "adult"
        [ set adult-fire-deaths adult-fire-deaths + 1 ]
        [ set elderly-fire-deaths elderly-fire-deaths + 1 ]
      ]
      die
    ]
  ]

  ;; kill exit door
  set oldgoal FALSE
  ask doors [
    if [ pcolor ] of patch-here = orange [set oldgoal true
      die ]
  ]
;  let shortest 0
  ask survivors [ set goal min-one-of doors [distance myself]
  ]
end

to register-escape
  ifelse color = blue
  [ set blue-escapees blue-escapees + 1 ]
  [ ifelse color = cyan
    [ set cyan-escapees cyan-escapees + 1 ]
    [ ifelse color = yellow
      [ set yellow-escapees yellow-escapees + 1 ]
      [ ifelse color = red
        [ set red-escapees red-escapees + 1 ]
        [ ifelse color = 29
          [ set beige-escapees beige-escapees + 1 ]
          [ set green-escapees green-escapees + 1 ]
        ]
      ]
    ]
  ]

  ifelse gender = "female"
  [ set female-escapees female-escapees + 1 ]
  [ set male-escapees male-escapees + 1 ]

  ifelse age = "child"
  [ set child-escapees child-escapees + 1 ]
  [ ifelse age = "adult"
    [ set adult-escapees adult-escapees + 1 ]
    [ set elderly-escapees elderly-escapees + 1 ]
  ]
end


to move-normal
  ask survivors [
    let next-patch 0

    ; Wybierz patch najbliższy do celu (wyjścia)
    if goal = door 14178 [
      set next-patch min-one-of neighbors with [pcolor != black] [distance1]
    ]
    if goal = door 14179 [
      set next-patch min-one-of neighbors with [pcolor != black] [distance2]
    ]
    if goal = door 14180 [
      set next-patch min-one-of neighbors with [pcolor != black] [distance3]
    ]
    if goal = door 14181 [
      set next-patch min-one-of neighbors with [pcolor != black] [distance4]
    ]
    if goal = door 14182 [
      set next-patch min-one-of neighbors with [pcolor != black] [distance5]
    ]
    if goal = door 14183 [
      set next-patch min-one-of neighbors with [pcolor != black] [distance6]
    ]
    if goal = door 14184 [
      set next-patch min-one-of neighbors with [pcolor != black] [distance7]
    ]
    if goal = door 14185 [
      set next-patch min-one-of neighbors with [pcolor != black] [distance8]
    ]
    if goal = door 14186 [
      set next-patch min-one-of neighbors with [pcolor != black] [distance9]
    ]
    if goal = door 14187 [
      set next-patch min-one-of neighbors with [pcolor != black] [distance10]
    ]

    ; Ruch w kierunku wybranego patcha
    repeat speed [
      ; Jeśli patch jest niedostępny, poszukaj innego
      while [next-patch != 0 and [pcolor] of next-patch != grey] [
        set next-patch min-one-of neighbors with [pcolor != black] [distance myself]
      ]

      ; Jeśli patch jest dostępny, przesuń się
      if next-patch != 0 and not patch-overcrowded? next-patch [
        move-to next-patch
      ]
    ]

    ; Jeśli agent dotarł do wyjścia
    if any? doors-here [
      register-escape
      die
    ]
  ]
end



to follow-crowd
  ask survivors [
    let next-patch 0

    ; Sprawdź, czy agent widzi wyjście
    if any? patches in-radius vision with [any? doors-here] [
      set goal min-one-of doors in-radius vision [distance myself]
      let goal-x [pxcor] of goal
      let goal-y [pycor] of goal
      set next-patch min-one-of neighbors with [pcolor = grey or pcolor = lime] [
        distancexy goal-x goal-y
      ]
    ]



    ; Jeśli agent nie widzi wyjścia, podążaj za innymi agentami
    if next-patch = 0 and any? turtles-on neighbors [
      let avg-heading mean [heading] of turtles-on neighbors
      set heading avg-heading
      set next-patch patch-ahead 1
      if [pcolor] of next-patch != grey and [pcolor] of next-patch != lime [
        set next-patch 0
      ]
    ]

    ; Jeśli agent widzi ogień, uciekaj w przeciwną stronę
    if next-patch = 0 and ([pcolor] of patch-here = orange or [pcolor] of patch-ahead 1 = orange) [
      set next-patch max-one-of neighbors with [pcolor = grey or pcolor = lime] [distancefire]
    ]

    ; Losowy ruch w przypadku braku innych opcji
    if next-patch = 0 or next-patch = nobody [
      set next-patch one-of neighbors with [pcolor = grey or pcolor = lime]
    ]

    ; Ruch do wybranego patcha
    if next-patch != 0 and not patch-overcrowded? next-patch [
      move-to next-patch
    ]

    ; Jeśli agent dotarł do wyjścia
    if any? doors-here [
      register-escape
      die
    ]
  ]
end





to setup-stadium
  draw-rectangle -163 135 321 105 gray
  create-blue1
  create-blue2
  create-blue3
  create-cyan1
  create-cyan2
  create-cyan3
  create-yellow1
  create-yellow2
  create-yellow3
  create-yellow4
  create-yellow5
  create-lime1
  create-lime2
  create-lime3
  create-green1
  create-green2
  create-green3
  draw-rectangle -250 25 500 8 gray
  draw-rectangle -14 17 25 18 white ;draw center bridge
  ;draw-black
  draw-leftbridge
  draw-rightbridge
  draw-rectangle -114 3 228 80 gray  ;draw floating platform
  create-stairs1 ;create all left-facing stairs
  create-stairs2 ;create all right-facing stairs
end

to set-survivors-attributes
  ask survivors [
    ; Set gender
    ifelse random-float 1.0 < 0.4805
    [ set gender "male" ]
    [ set gender "female" ]

    ; Set age
    ifelse random-float 1.0 <= 0.1498
    [ set age "child" ]
    [ ifelse random-float 1.0 < 0.8708
      [ set age "adult" ]
      [ set age "elderly" ]
    ]
;    set age random-normal 42.4 20

    ; Set base speed
    ifelse age = "child"
    [ set base-speed 0.3889 ] ; 1.4km/h = 0.38889m/s
    [ ifelse age = "adult"
      [ set base-speed random-float-between 1.4778 1.5083 ] ; 5.32km/h = 1.4778m/s and 5.43km/h = 1.5083m/s
      [ set base-speed random-float-between 1.2528 1.3194 ] ; 4.51km/h = 1.2528m/s and 4.75km/h = 1.3194m/s
    ]
    set speed base-speed
;    ifelse age < 15
;    [ set speed 1.4 ]
;    [ ifelse age < 65
;      [ set speed random-float-between 5.32 5.43 ]
;      [ set speed random-float-between 4.51 4.75 ]
;    ]

    ; Set mass
    ifelse age = "child"
    [ ifelse gender = "male"
      [ set mass random-normal 40 4]
      [ set mass random-normal 35 4]
    ]
    [ set mass random-normal 57.7 4 ]
    ; Set health
    set health mass * speed * threshold
;    show health

    ; Set vision
    set vision random max-vision

    ; Set panic level
    set panic 1
  ]
end

to-report random-float-between [ #min #max ]  ; random float in given range
  report #min + random-float (#max - #min)
end

to-report patch-overcrowded? [ p ]
  if p = nobody [report false]
  report count turtles-on p > 10
end


to create-stairs1
  let xlist create-xlist4 82
  let ylist create-ylist2 5 30
  (foreach xlist ylist [ [x y] ->
    draw-rectangle x y 2 1 gray
    ])
  set xlist create-xlist4 44
  set ylist create-ylist2 5 30
  (foreach xlist ylist [ [x y] ->
    draw-rectangle x y 2 1 gray
    ])
  set xlist create-xlist4 -33
  set ylist create-ylist2 5 30
  (foreach xlist ylist [ [x y] ->
    draw-rectangle x y 2 1 gray
    ])
  set xlist create-xlist4 -70
  set ylist create-ylist2 5 30
  (foreach xlist ylist [ [x y] ->
    draw-rectangle x y 2 1 gray
    ])
  set xlist create-xlist4 -127
  set ylist create-ylist2 5 30
  (foreach xlist ylist [ [x y] ->
    draw-rectangle x y 2 1 gray
    ])
end

to create-stairs2
  let xlist create-xlist5 121
  let ylist create-ylist2 5 30
  (foreach xlist ylist [ [x y] ->
    draw-rectangle x y 2 1 gray
    ])
  set xlist create-xlist5 64
  set ylist create-ylist2 5 30
  (foreach xlist ylist [ [x y] ->
    draw-rectangle x y 2 1 gray
    ])
  set xlist create-xlist5 26
  set ylist create-ylist2 5 30
  (foreach xlist ylist [ [x y] ->
    draw-rectangle x y 2 1 gray
    ])
  set xlist create-xlist5 -50
  set ylist create-ylist2 5 30
  (foreach xlist ylist [ [x y] ->
    draw-rectangle x y 2 1 gray
    ])
  set xlist create-xlist5 -88
  set ylist create-ylist2 5 30
  (foreach xlist ylist [ [x y] ->
    draw-rectangle x y 2 1 gray
    ])
end

to create-blue1
  let ylist create-ylist 17 135
  let peoplelist create-peoplelist 17 -163
  (foreach ylist [ [y] ->
    draw-rectangle -163 y 17 1 blue
   (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color blue set heading 180]])
    ])
  set ylist create-ylist 17 100
  (foreach ylist [ [y] ->
    draw-rectangle -163 y 17 1 blue
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color blue set heading 180]])
    ])
  let xlist create-xlist -163
  set ylist create-ylist 17 65
  let wlist create-wlist 17
  (foreach xlist ylist wlist [ [x y w] ->
    draw-rectangle x y w 1 blue
    set peoplelist create-peoplelist w x
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color blue set heading 180]])
    ])
end
to create-blue2
  let ylist create-ylist 17 135
  let peoplelist create-peoplelist 17 -144
  (foreach ylist [ [y] ->
    draw-rectangle -144 y 17 1 blue
    ;(foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color blue set heading 180]])
    ])
  set ylist create-ylist 17 100
  (foreach ylist [ [y] ->
    draw-rectangle -144 y 17 1 blue
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color blue set heading 180]])
    ])
  set ylist create-ylist 17 65
  (foreach ylist [ [y] ->
    draw-rectangle -144 y 17 1 blue
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color blue set heading 180]])
    ])
end
to create-blue3
  let ylist create-ylist 17 135
  let peoplelist create-peoplelist 17 -125
  (foreach ylist [ [y] ->
    draw-rectangle -125 y 17 1 blue
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color blue set heading 180]])
    ])
  set ylist create-ylist 17 100
  (foreach ylist [ [y] ->
    draw-rectangle -125 y 17 1 blue
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color blue set heading 180]])
    ])
  set ylist create-ylist 17 65
  (foreach ylist [ [y] ->
    draw-rectangle -125 y 17 1 blue
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color blue set heading 180]])
    ])
end

to create-cyan1
  let ylist create-ylist 17 135
  let peoplelist create-peoplelist 17 -106
  (foreach ylist [ [y] ->
    draw-rectangle -106 y 17 1 cyan
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color cyan set heading 180]])
    ])
  set ylist create-ylist 17 100
  (foreach ylist [ [y] ->
    draw-rectangle -106 y 17 1 cyan
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color cyan set heading 180]])
    ])
  set ylist create-ylist 17 65
  (foreach ylist [ [y] ->
    draw-rectangle -106 y 17 1 cyan
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color cyan set heading 180]])
    ])
end
to create-cyan2
  let ylist create-ylist 17 135
  let peoplelist create-peoplelist 17 -87
  (foreach ylist [ [y] ->
    draw-rectangle -87 y 17 1 cyan
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color cyan set heading 180]])
    ])
  set ylist create-ylist 17 100
  (foreach ylist [ [y] ->
    draw-rectangle -87 y 17 1 cyan
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color cyan set heading 180]])
    ])
  set ylist create-ylist 17 65
  (foreach ylist [ [y] ->
    draw-rectangle -87 y 17 1 cyan
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color cyan set heading 180]])
    ])
end
to create-cyan3
  let ylist create-ylist 17 135
  let peoplelist create-peoplelist 17 -68
  (foreach ylist [ [y] ->
    draw-rectangle -68 y 17 1 cyan
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color cyan set heading 180]])
    ])
  set ylist create-ylist 17 100
  (foreach ylist [ [y] ->
    draw-rectangle -68 y 17 1 cyan
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color cyan set heading 180]])
    ])
  set ylist create-ylist 17 65
  (foreach ylist [ [y] ->
    draw-rectangle -68 y 17 1 cyan
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color cyan set heading 180]])
    ])
end

to create-yellow1
  let ylist create-ylist 17 135
  let peoplelist create-peoplelist 17 -49
  (foreach ylist [ [y] ->
    draw-rectangle -49 y 17 1 yellow
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color yellow set heading 180]])
    ])
  set ylist create-ylist 17 100
  (foreach ylist [ [y] ->
    draw-rectangle -49 y 17 1 yellow
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color yellow set heading 180]])
    ])
  set ylist create-ylist 17 65
  (foreach ylist [ [y] ->
    draw-rectangle -49 y 17 1 yellow
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color yellow set heading 180]])
    ])
end
to create-yellow2
  let ylist create-ylist 17 135
  let peoplelist create-peoplelist 17 -30
  (foreach ylist [ [y] ->
    draw-rectangle -30 y 17 1 yellow
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color yellow set heading 180]])
    ])
  set ylist create-ylist 17 100
  (foreach ylist [ [y] ->
    draw-rectangle -30 y 17 1 red
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color red set heading 180]])
    ])
  set ylist create-ylist 17 65
  (foreach ylist [ [y] ->
    draw-rectangle -30 y 17 1 red
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color red set heading 180]])
    ])
end
to create-yellow3
  let ylist create-ylist 17 135
  let peoplelist create-peoplelist 17 -11
  (foreach ylist [ [y] ->
    draw-rectangle -11 y 17 1 yellow
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color yellow set heading 180]])
    ])
  set ylist create-ylist 17 100
  (foreach ylist [ [y] ->
    draw-rectangle -11 y 17 1 red
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color red set heading 180]])
    ])
  set ylist create-ylist 17 65
  (foreach ylist [ [y] ->
    draw-rectangle -11 y 17 1 red
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color red set heading 180]])
    ])
end
to create-yellow4
  let ylist create-ylist 17 135
  let peoplelist create-peoplelist 17 8
  (foreach ylist [ [y] ->
    draw-rectangle 8 y 17 1 yellow
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color yellow set heading 180]])
    ])
  set ylist create-ylist 17 100
  (foreach ylist [ [y] ->
    draw-rectangle 8 y 17 1 red
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color red set heading 180]])
    ])
  set ylist create-ylist 17 65
  (foreach ylist [ [y] ->
    draw-rectangle 8 y 17 1 red
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color red set heading 180]])
    ])
end
to create-yellow5
  let ylist create-ylist 17 135
  let peoplelist create-peoplelist 17 27
  (foreach ylist [ [y] ->
    draw-rectangle 27 y 17 1 yellow
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color yellow set heading 180]])
    ])
  set ylist create-ylist 17 100
  (foreach ylist [ [y] ->
    draw-rectangle 27 y 17 1 yellow
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color yellow set heading 180]])
    ])
  set ylist create-ylist 17 65
  (foreach ylist [ [y] ->
    draw-rectangle 27 y 17 1 yellow
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color yellow set heading 180]])
    ])
end

to create-lime1
  let ylist create-ylist 17 135
  let peoplelist create-peoplelist 17 46
  (foreach ylist [ [y] ->
    draw-rectangle 46 y 17 1 29
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color 29 set heading 180]])
    ])
  set ylist create-ylist 17 100
  (foreach ylist [ [y] ->
    draw-rectangle 46 y 17 1 29
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color 29 set heading 180]])
    ])
  set ylist create-ylist 17 65
  (foreach ylist [ [y] ->
    draw-rectangle 46 y 17 1 29
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color 29 set heading 180]])
    ])
end
to create-lime2
  let ylist create-ylist 17 135
  let peoplelist create-peoplelist 17 65
  (foreach ylist [ [y] ->
    draw-rectangle 65 y 17 1 29
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color 29 set heading 180]])
    ])
  set ylist create-ylist 17 100
  (foreach ylist [ [y] ->
    draw-rectangle 65 y 17 1 29
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color 29 set heading 180]])
    ])
  set ylist create-ylist 17 65
  (foreach ylist [ [y] ->
    draw-rectangle 65 y 17 1 29
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color 29 set heading 180]])
    ])
end
to create-lime3
  let ylist create-ylist 17 135
  let peoplelist create-peoplelist 17 84
  (foreach ylist [ [y] ->
    draw-rectangle 84 y 17 1 29
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color 29 set heading 180]])
    ])
  set ylist create-ylist 17 100
  (foreach ylist [ [y] ->
    draw-rectangle 84 y 17 1 29
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color 29 set heading 180]])
    ])
  set ylist create-ylist 17 65
  (foreach ylist [ [y] ->
    draw-rectangle 84 y 17 1 29
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color 29 set heading 180]])
    ])
end

to create-green1
  let ylist create-ylist 17 135
  let peoplelist create-peoplelist 17 103
  (foreach ylist [ [y] ->
    draw-rectangle 103 y 17 1 green
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color green set heading 180]])
    ])
  set ylist create-ylist 17 100
  (foreach ylist [ [y] ->
    draw-rectangle 103 y 17 1 green
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color green set heading 180]])
    ])
  set ylist create-ylist 17 65
  (foreach ylist [ [y] ->
    draw-rectangle 103 y 17 1 green
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color green set heading 180]])
    ])
end
to create-green2
  let ylist create-ylist 17 135
  let peoplelist create-peoplelist 17 122
  (foreach ylist [ [y] ->
    draw-rectangle 122 y 17 1 green
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color green set heading 180]])
    ])
  set ylist create-ylist 17 100
  (foreach ylist [ [y] ->
    draw-rectangle 122 y 17 1 green
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color green set heading 180]])
    ])
  set ylist create-ylist 17 65
  (foreach ylist [ [y] ->
    draw-rectangle 122 y 17 1 green
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color green set heading 180]])
    ])
end
to create-green3
  let ylist create-ylist 17 135
  let peoplelist create-peoplelist 17 141
  (foreach ylist [ [y] ->
    draw-rectangle 141 y 17 1 green
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color green set heading 180]])
    ])
  set ylist create-ylist 17 100
  (foreach ylist [ [y] ->
    draw-rectangle 141 y 17 1 green
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color green set heading 180]])
    ])
  set ylist create-ylist 17 65
  let wlist create-wlist 17
  (foreach ylist wlist [ [y w] ->
    draw-rectangle 141 y w 1 green
    set peoplelist create-peoplelist w 141
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color green set heading 180]])
    ])
end

to-report create-xlist5 [input]
  report n-values (5) [ [i] -> input - i * 1]
end

to-report create-xlist4 [input]
  report n-values (5) [ [i] -> input + i * 1]
end

to-report create-xlist3 [input]
  report n-values (14) [ [i] -> input - i * 1]
end

to-report create-xlist2 [input]
  report n-values (14) [ [i] -> input + i * 1]
end

to-report create-ylist2 [input1 input2]
  report n-values (input1) [ [i] -> input2 - i * 1]
end

to-report create-xlist [input]
  report n-values (17) [ [i] -> input + i * 1]
end

to-report create-ylist [input1 input2]
  report n-values (input1) [ [i] -> input2 - i * 2]
end

to-report create-wlist [input]
  report n-values (17) [ [i] -> input - i * 1]
end

to-report create-peoplelist [input1 input2]
  report n-values (input1) [ [i] -> input2 + i]
end

to draw-rectangle [ x y w l c ]
  ask patches with
  [ w + x > pxcor and pxcor >= x
    and
    y >= pycor and pycor > (y - l) ] [ set pcolor c ]
end

to draw-leftbridge
  let xlist create-xlist2 -120
  let ylist create-ylist2 14 17
  (foreach xlist ylist [ [x y] ->
    draw-rectangle x y 17 1 white
    ])
end

to draw-rightbridge
  let xlist create-xlist3 94
  let ylist create-ylist2 14 17
  (foreach xlist ylist [ [x y] ->
    draw-rectangle x y 17 1 white
    ])
end
