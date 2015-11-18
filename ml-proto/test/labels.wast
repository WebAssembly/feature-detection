(module
  (func $block (result i32)
    (block $exit
      (br $exit (i32.const 1))
      (i32.const 0)
    )
  )

  (func $loop1 (result i32)
    (local $i i32)
    (set_local $i (i32.const 0))
    (loop $exit $cont
      (set_local $i (i32.add (get_local $i) (i32.const 1)))
      (if (i32.eq (get_local $i) (i32.const 5))
        (br $exit (get_local $i))
      )
      (br $cont)
    )
  )

  (func $loop2 (result i32)
    (local $i i32)
    (set_local $i (i32.const 0))
    (loop $exit $cont
      (set_local $i (i32.add (get_local $i) (i32.const 1)))
      (if (i32.eq (get_local $i) (i32.const 5))
        (br $cont)
      )
      (if (i32.eq (get_local $i) (i32.const 8))
        (br $exit (get_local $i))
      )
      (set_local $i (i32.add (get_local $i) (i32.const 1)))
      (br $cont)
    )
  )

  (func $switch (param i32) (result i32)
    (label $ret
      (i32.mul (i32.const 10)
        (tableswitch $exit (get_local 0)
          (table (case $0) (case $1) (case $2) (case $3)) (case $default)
          (case $1 (i32.const 1))
          (case $2 (br $exit (i32.const 2)))
          (case $3 (br $ret (i32.const 3)))
          (case $default (i32.const 4))
          (case $0 (i32.const 5))
        )
      )
    )
  )

  (func $return (param i32) (result i32)
    (tableswitch (get_local 0)
      (table (case $0) (case $1)) (case $default)
      (case $0 (return (i32.const 0)))
      (case $1 (i32.const 1))
      (case $default (i32.const 2))
    )
  )

  (export "block" $block)
  (export "loop1" $loop1)
  (export "loop2" $loop2)
  (export "switch" $switch)
  (export "return" $return)
)

(assert_return (invoke "block") (i32.const 1))
(assert_return (invoke "loop1") (i32.const 5))
(assert_return (invoke "loop2") (i32.const 8))
(assert_return (invoke "switch" (i32.const 0)) (i32.const 50))
(assert_return (invoke "switch" (i32.const 1)) (i32.const 20))
(assert_return (invoke "switch" (i32.const 2)) (i32.const 20))
(assert_return (invoke "switch" (i32.const 3)) (i32.const 3))
(assert_return (invoke "switch" (i32.const 4)) (i32.const 50))
(assert_return (invoke "switch" (i32.const 5)) (i32.const 50))
(assert_return (invoke "return" (i32.const 0)) (i32.const 0))
(assert_return (invoke "return" (i32.const 1)) (i32.const 2))
(assert_return (invoke "return" (i32.const 2)) (i32.const 2))

