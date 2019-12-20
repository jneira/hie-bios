module FuncTest where

import System.Process
import Test.Tasty
import Test.Tasty.HUnit

runHieBios :: FilePath -> [String] -> String
runHieBios wdir args = (proc "hie-bios" args) { cwd = Just wdir }

main :: IO
main = 
  defaultMain $ 
    testGroup "Functional-tests"
      [ testGroup "check command" ]