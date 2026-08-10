<?php

// Starter php-cs-fixer config shipped by oc-githooks. Adjust rules to your
// team's standard. Having a config also lets php-cs-fixer run on a file list.
$finder = PhpCsFixer\Finder::create()
    ->in(__DIR__)
    ->exclude('vendor');

return (new PhpCsFixer\Config())
    ->setRules([
        '@PSR12' => true,
    ])
    ->setFinder($finder);
