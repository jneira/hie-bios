{-# LANGUAGE CPP #-}
-- | Pretty printer utilities
module HIE.Bios.Ghc.Doc where

import GHC (DynFlags, getPrintUnqual, pprCols, GhcMonad)

#if __GLASGOW_HASKELL__ >= 900
import GHC.Utils.Ppr (Mode(..), Doc, Style(..), renderStyle, style)
import GHC.Utils.Outputable (PprStyle, SDoc, neverQualify, runSDoc)
import GHC.Driver.Session (initSDocContext)
#else
import Pretty (Mode(..), Doc, Style(..), renderStyle, style)
import Outputable (PprStyle, SDoc, withPprStyleDoc, neverQualify)
#endif

import HIE.Bios.Ghc.Gap (makeUserStyle)

#if __GLASGOW_HASKELL__ >= 900
withPprStyleDoc :: DynFlags -> PprStyle -> SDoc -> Doc
withPprStyleDoc dflags sty d = runSDoc d (initSDocContext dflags sty)
#endif

showPage :: DynFlags -> PprStyle -> SDoc -> String
showPage dflag stl = showDocWith dflag PageMode . withPprStyleDoc dflag stl

showOneLine :: DynFlags -> PprStyle -> SDoc -> String
showOneLine dflag stl = showDocWith dflag OneLineMode . withPprStyleDoc dflag stl

getStyle :: (GhcMonad m) => DynFlags -> m PprStyle
getStyle dflags = makeUserStyle dflags <$> getPrintUnqual

styleUnqualified :: DynFlags -> PprStyle
styleUnqualified dflags = makeUserStyle dflags neverQualify

showDocWith :: DynFlags -> Mode -> Doc -> String
showDocWith dflags md = renderStyle mstyle
  where
    mstyle = style { mode = md, lineLength = pprCols dflags }
