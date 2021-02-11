{-# LANGUAGE FlexibleInstances, CPP #-}
-- | All the CPP for GHC version compability should live in this module.
module HIE.Bios.Ghc.Gap (
    WarnFlags
  , emptyWarnFlags
  , makeUserStyle
  , getModuleName
  , getTyThing
  , fixInfo
  , getModSummaries
  , mapOverIncludePaths
  , LExpression
  , LBinding
  , LPattern
  , inTypes
  , outType
  , mapMG
  , mgModSummaries
  , numLoadedPlugins
  , initializePlugins
  , unsetLogAction
  ) where


import GHC(LHsBind, LHsExpr, LPat, Type, ModSummary, ModuleGraph, HscEnv, setLogAction, GhcMonad)

#if __GLASGOW_HASKELL__ >= 900
import GHC.Driver.Session (DynFlags, includePaths)
import GHC.Utils.Outputable (PrintUnqualified, PprStyle, Depth(AllTheWay), mkUserStyle)
#else
import DynFlags (DynFlags, includePaths)
import Outputable (PrintUnqualified, PprStyle, Depth(AllTheWay), mkUserStyle)
#endif

#if __GLASGOW_HASKELL__ >= 900
import qualified GHC.Runtime.Loader as DynamicLoading (initializePlugins)
import qualified GHC.Driver.Plugins as Plugins (plugins)
#elif __GLASGOW_HASKELL__ >= 808
import qualified DynamicLoading (initializePlugins)
import qualified Plugins (plugins)
#endif

----------------------------------------------------------------
----------------------------------------------------------------

#if __GLASGOW_HASKELL__ >= 900
import GHC.Driver.Session (WarningFlag)
import qualified GHC.Data.EnumSet as E (EnumSet, empty)
#elif __GLASGOW_HASKELL__ >= 804
import DynFlags (WarningFlag)
import qualified EnumSet as E (EnumSet, empty)
#endif

#if __GLASGOW_HASKELL__ >= 804
import GHC (mgModSummaries, mapMG)
#endif

#if __GLASGOW_HASKELL__ >= 900
import GHC.Driver.Session (IncludeSpecs(..))
#elif __GLASGOW_HASKELL__ >= 806
import DynFlags (IncludeSpecs(..))
#endif

#if __GLASGOW_HASKELL__ >= 900
import GHC.Core.Type (irrelevantMult)
#endif

#if __GLASGOW_HASKELL__ >= 810
import GHC.Hs.Extension (GhcTc)
import GHC.Hs.Expr (MatchGroup, MatchGroupTc(..), mg_ext)
#elif __GLASGOW_HASKELL__ >= 806
import HsExtension (GhcTc)
import HsExpr (MatchGroup, MatchGroupTc(..))
import GHC (mg_ext)
#elif __GLASGOW_HASKELL__ >= 804
import HsExtension (GhcTc)
import HsExpr (MatchGroup)
import GHC (mg_res_ty, mg_arg_tys)
#else
import HsExtension (GhcTc)
import HsExpr (MatchGroup)
#endif

----------------------------------------------------------------
----------------------------------------------------------------

makeUserStyle :: DynFlags -> PrintUnqualified -> PprStyle
#if __GLASGOW_HASKELL__ >= 900
makeUserStyle dflags style = mkUserStyle style AllTheWay
#elif __GLASGOW_HASKELL__ >= 804
makeUserStyle dflags style = mkUserStyle dflags style AllTheWay
#endif

#if __GLASGOW_HASKELL__ >= 804
getModuleName :: (a, b) -> a
getModuleName = fst
#endif

----------------------------------------------------------------

#if __GLASGOW_HASKELL__ >= 804
type WarnFlags = E.EnumSet WarningFlag
emptyWarnFlags :: WarnFlags
emptyWarnFlags = E.empty
#endif

#if __GLASGOW_HASKELL__ >= 804
getModSummaries :: ModuleGraph -> [ModSummary]
getModSummaries = mgModSummaries

getTyThing :: (a, b, c, d, e) -> a
getTyThing (t,_,_,_,_) = t

fixInfo :: (a, b, c, d, e) -> (a, b, c, d)
fixInfo (t,f,cs,fs,_) = (t,f,cs,fs)
#endif

----------------------------------------------------------------

mapOverIncludePaths :: (FilePath -> FilePath) -> DynFlags -> DynFlags
mapOverIncludePaths f df = df
  { includePaths = 
#if __GLASGOW_HASKELL__ > 804
      IncludeSpecs
          (map f $ includePathsQuote  (includePaths df))
          (map f $ includePathsGlobal (includePaths df))
#else
      map f (includePaths df)
#endif
  }

----------------------------------------------------------------
#if __GLASGOW_HASKELL__ >= 804

type LExpression = LHsExpr GhcTc
type LBinding    = LHsBind GhcTc
type LPattern    = LPat    GhcTc

inTypes :: MatchGroup GhcTc LExpression -> [Type]
outType :: MatchGroup GhcTc LExpression -> Type

#if __GLASGOW_HASKELL__ >= 900
inTypes = map irrelevantMult . mg_arg_tys . mg_ext
outType = mg_res_ty . mg_ext
#elif __GLASGOW_HASKELL__ >= 806
inTypes = mg_arg_tys . mg_ext
outType = mg_res_ty . mg_ext
#else
inTypes = mg_arg_tys
outType = mg_res_ty
#endif

#endif

numLoadedPlugins :: DynFlags -> Int
#if __GLASGOW_HASKELL__ >= 808
numLoadedPlugins = length . Plugins.plugins
#else
-- Plugins are loaded just as they are used
numLoadedPlugins _ = 0
#endif

initializePlugins :: HscEnv -> DynFlags -> IO DynFlags
#if __GLASGOW_HASKELL__ >= 808
initializePlugins = DynamicLoading.initializePlugins
#else
-- In earlier versions of GHC plugins are just loaded before they are used.
initializePlugins _ df = return df
#endif

unsetLogAction :: GhcMonad m => m ()
unsetLogAction =
#if __GLASGOW_HASKELL__ >= 900
    setLogAction (\_df _wr _s _ss _sd -> return ())
#else
    setLogAction (\_df _wr _s _ss _pp _m -> return ())
#endif
#if __GLASGOW_HASKELL__ < 806
        (\_df -> return ())
#endif