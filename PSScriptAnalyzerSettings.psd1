@{
    Severity = @('Error', 'Warning')
    IncludeRules = @(
        'PSAvoidUsingCmdletAliases',
        'PSAvoidUsingEmptyCatchBlock',
        'PSAvoidUsingInvokeExpression',
        'PSAvoidUsingPlainTextForPassword',
        'PSAvoidUsingUsernameAndPasswordParams',
        'PSUseApprovedVerbs',
        'PSUseBOMForUnicodeEncodedFile',
        'PSUseCorrectCasing',
        'PSUseDeclaredVarsMoreThanAssignments',
        'PSUsePSCredentialType',
        'PSUseShouldProcessForStateChangingFunctions'
    )
    ExcludeRules = @(
        'PSAvoidUsingWriteHost',
        'PSUseSingularNouns',
        'PSAvoidUsingPositionalParameters',
        'PSReviewUnusedParameter',
        'PSAvoidGlobalVars'
    )
    Rules = @{
        PSUseApprovedVerbs = @{
            Enable = $true
        }
        PSAvoidUsingCmdletAliases = @{
            Enable = $true
            AllowList = @('foreach', 'filter', 'where', 'select')
        }
    }
}
