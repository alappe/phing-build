# phing-build

This is a collection of several files that can be used to test and
analyse TYPO3-Extensions from a phing-compatible environment (e.g.
Jenkins).

While not all of this is a long-term solution, this scratched the itch
to continuously test extensions and be notified for build errors or
warnings.

## Usage

From withhin your extension:

``` […/typo3conf/ext] % git submodule add git@github.com:alappe/phing-build.git Resources/Private/Phing
[…/typo3conf/ext] % ln -s Resources/Private/Phing/build.xml .
[…/typo3conf/ext] % cp Resources/Private/Phing/build.properties .
[…/typo3conf/ext] % 
```

Then edit your build.properties file to adjust it to your environment.
