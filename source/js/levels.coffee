@levels = []

@levels.push
  waves: [
    {start_time: 0, spawns : {asteroid : 15, sob: 1}}
  ]

@levels.push
  waves: [
    {start_time: 0, spawns : {asteroid : 15, jerk : 1}}
    {start_time : 4000, spawns: {jerk : 1}}
    {start_time : 4000, spawns: {jerk : 1}}
    {start_time : 4000, spawns: {jerk : 2}}
  ]


@levels.push
  waves: [
    {start_time: 0, spawns : {asteroid : 15, jerk : 1}}
    {start_time: 2000, spawns : {asteroid : 1, bub : 1}}
    {start_time : 4000, spawns: {jerk : 2, asteroid: 2, bub: 1}}
    {start_time : 4000, spawns: {jerk : 3, asteroid: 2}}
    {start_time : 2000, spawns: {jerk : 2, asteroid: 2, bub: 1}}
  ]

@levels.push
  waves: [
    {start_time: 0, spawns : {asteroid : 15, jerk : 1}}
    {start_time : 1000, spawns: {jerk : 1, asteroid: 1, bub: 1}}
    {start_time : 1000, spawns: {jerk : 1, asteroid: 1, bub: 1}}
    {start_time : 1000, spawns: {jerk : 1, asteroid: 1, bub: 1}}
    {start_time : 500, spawns: {jerk : 1, asteroid: 1, bub: 1}}
    {start_time : 4000, spawns: {jerk : 3, asteroid: 2, bub: 1}}
    {start_time : 2000, spawns: {jerk : 2, asteroid: 2, bub: 1}}
  ]

@levels.push
  waves: [
    {start_time: 0, spawns : {asteroid : 15, jerk : 1}}
    {start_time: 5000, spawns : {jerk : 5, bub: 5}}
    {start_time: 5000, spawns : {jerk : 5, bub: 3}}
    {start_time: 5000, spawns : {jerk : 5, bub: 3}}
    {start_time: 5000, spawns : {jerk : 5, bub: 3}}
    {start_time: 5000, spawns : {jerk : 5, bub: 3}}
  ]

@levels.push
  waves: [
    {start_time: 0, spawns : {asteroid : 15, jerk : 1}}
    {start_time: 5000, spawns : {jerk : 5, bub: 5}}
    {start_time: 5000, spawns : {jerk : 5, bub: 3}}
    {start_time: 5000, spawns : {jerk : 5, bub: 3}}
    {start_time: 5000, spawns : {jerk : 5, bub: 3}}
    {start_time: 5000, spawns : {jerk : 5, bub: 3}}
  ]
