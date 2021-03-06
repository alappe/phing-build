<?php
/***************************************************************
 * Copyright notice
 *
 * (c) 2010 Stefano Kowalke <blueduck@gmx.net>
 * All rights reserved
 *
 * This script is part of the TYPO3 project. The TYPO3 project is
 * free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * The GNU General Public License can be found at
 * http://www.gnu.org/copyleft/gpl.html.
 *
 * This script is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * This copyright notice MUST APPEAR in all copies of the script!
 ***************************************************************/
/**
 * TYPO3_Sniffs_NamingConventions_ValidVariableNameSniff.
 *
 * PHP version 5
 * TYPO3 version 4
 *
 * @category  NamingConventions
 * @package   TYPO3_PHPCS_Pool
 * @author    Stefano Kowalke <blueduck@gmx.net>
 * @author    Andy Grunwald <andreas.grunwald@wmdb.de>
 * @copyright Copyright (c) 2010, Stefano Kowalke, Andy Grunwald
 * @license   http://www.gnu.org/copyleft/gpl.html GNU Public License
 * @version   SVN: $Id$
 * @link      http://pear.typo3.org
 */
if (class_exists('PHP_CodeSniffer_Standards_AbstractVariableSniff', TRUE) === FALSE) {
    $error = 'Class PHP_CodeSniffer_Standards_AbstractVariableSniff not found';
    throw new PHP_CodeSniffer_Exception($error);
}
/**
 * Checks the naming of member variables.
 * All identifiers must use camelCase and start with a lower case letter.
 * Underscore characters are not allowed.
 *
 * @category  NamingConventions
 * @package   TYPO3_PHPCS_Pool
 * @author    Stefano Kowalke <blueduck@gmx.net>
 * @author    Andy Grunwald <andreas.grunwald@wmdb.de>
 * @copyright Copyright (c) 2010, Stefano Kowalke, Andy Grunwald
 * @license   http://www.gnu.org/copyleft/gpl.html GNU Public License
 * @version   Release: @package_version@
 * @link      http://pear.typo3.org
 */
class TYPO3_Sniffs_NamingConventions_ValidVariableNameSniff extends PHP_CodeSniffer_Standards_AbstractVariableSniff {
    /**
     * Contains built-in TYPO3 variables which we don't check
     *
     * @var array $allowedTypo3InbuiltVariableNames
     */
	protected $allowedTypo3InbuiltVariableNames = array(
													'GLOBALS',
													'TYPO3_CONF_VARS',
													'TYPO3_LOADED_EXT',
													'TYPO3_DB',
													'EXEC_TIME',
													'SIM_EXEC_TIME',
													'TYPO_VERSION',
													'CLIENT',
													'PARSETIME_START',
													'PAGES_TYPES',
													'ICON_TYPES',
													'LANG_GENERAL_LABELS',
													'TCA',
													'TBE_MODULES',
													'TBE_STYLES',
													'T3_SERVICES',
													'T3_VAR',
													'FILEICONS',
													'WEBMOUNTS',
													'FILEMOUNTS',
													'BE_USER',
													'TBE_MODULES_EXT',
													'TCA_DESCR',
													'_EXTKEY',
													'EM_CONF',
													'LANG',
													'BACK_PATH',
													'_REQUEST',
													'_SERVER',
													'_REQUEST',
													'_COOKIE',
													'_FILES'
												);

	/**
     * Processes class member variables.
     *
     * @param PHP_CodeSniffer_File  $phpcsFile  The file being scanned.
     * @param int                   $stackPtr   The position of the current token in the stack passed in $tokens.
     *
     * @return void
     */
    protected function processMemberVar(PHP_CodeSniffer_File $phpcsFile, $stackPtr) {
        $memberProps = $phpcsFile->getMemberProperties($stackPtr);
        if (empty($memberProps) === TRUE) {
            return;
        }
        $this->processVariableNameCheck($phpcsFile, $stackPtr, 'member ');
    }
    /**
     * Processes normal variables.
     *
     * @param PHP_CodeSniffer_File $phpcsFile The file where this token was found.
     * @param int                  $stackPtr  The position where the token was found.
     *
     * @return void
     */
    protected function processVariable(PHP_CodeSniffer_File $phpcsFile, $stackPtr) {
        $tokens = $phpcsFile->getTokens();
        $variableName = ltrim($tokens[$stackPtr]['content'], '$');
        $this->processVariableNameCheck($phpcsFile, $stackPtr);
    }
    /**
     * Processes variables in double quoted strings.
     *
     * @param PHP_CodeSniffer_File $phpcsFile The file where this token was found.
     * @param int                  $stackPtr  The position where the token was found.
     *
     * @return void
     */
    protected function processVariableInString(PHP_CodeSniffer_File $phpcsFile, $stackPtr) {
        // We don't care about variables in strings.
        return;
    }
    /**
     * Proceed the whole variable name check.
     * Checks if the variable name has underscores or is written in lowerCamelCase.
     *
     * @param PHP_CodeSniffer_File $phpcsFile
     * @param int                  $stackPtr  The position where the token was found.
     * @param string               $scope     The variable scope. For example "member" if variable is a class property.
     */
    protected function processVariableNameCheck(PHP_CodeSniffer_File $phpcsFile, $stackPtr, $scope = '') {
        $tokens = $phpcsFile->getTokens();
        $variableName = ltrim($tokens[$stackPtr]['content'], '$');
			// There are some historic builtin TYPO3 vars we don't care here.
			// if we found such vars, we leave the sniff here.
		if (in_array($variableName, $this->allowedTypo3InbuiltVariableNames)) {
			return;
		}

		$hasUnderscores = stripos($variableName, '_');
		$isLowerCamelCase = PHP_CodeSniffer::isCamelCaps($variableName, FALSE, TRUE, TRUE);
		if ($hasUnderscores !== FALSE) {
			$error = 'Underscores are not allowed in the ' . $scope . 'variablename "$' . $variableName . '"; ';
			$error.= 'use lowerCamelCase for identifier instead';
			$phpcsFile->addError($error, $stackPtr);
		} elseif ($isLowerCamelCase === FALSE) {
			$pattern = '/([A-Z]{1,}(?=[A-Z]?|[0-9]))/e';
			$replace = "ucfirst(strtolower('\\1'))";
			$variableNameLowerCamelCased =  preg_replace($pattern, $replace, $variableName);
			$error = ucfirst($scope) . 'variablename must be lowerCamelCase; expect "$' .
			$variableNameLowerCamelCased . '" but found "$' . $variableName . '"';
			$phpcsFile->addError($error, $stackPtr);
		}
	}
}
?>