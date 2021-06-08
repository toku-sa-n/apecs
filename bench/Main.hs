{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE Strict #-}

module Main (main) where

import Apecs
import Apecs.Stores (IOStore, newEntityIO)
import Control.Monad
import Control.Monad.State
import Criterion.Main
import Linear

newtype Pos = Pos (V2 Float)

newtype Vel = Vel (V2 Float)

data World
  = World
      (Cache 10000 (IntMap Pos) Pos)
      (Cache 1000 (IntMap Vel) Vel)
      (EntityCounter)
  deriving (Generic, Initialize IO)

benchInit :: System World ()
benchInit = do
  replicateM_ 1000 $ newEntity (Pos 0, Vel 0)
  replicateM_ 9000 $ newEntity (Pos 0)

benchStep :: System World ()
benchStep = cmap $ \(Vel v, Pos p) -> Pos (p + v)

main :: IO ()
main =
  defaultMain
    [ bgroup
        "pos_vel"
        [ bench "init" $ whnfIO (initialize >>= runReaderT benchInit),
          bench "step" $ whnfIO (initialize >>= runReaderT (benchInit >> benchStep)),
          bench "step 100" $ whnfIO (initialize >>= runReaderT (benchInit >> replicateM_ 100 benchStep))
        ]
    ]
