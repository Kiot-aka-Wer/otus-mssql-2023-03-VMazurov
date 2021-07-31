EXEC sp_configure 'clr strict security', 0;
EXEC sp_configure 'clr enabled', 1;
RECONFIGURE;

CREATE ASSEMBLY SplitStringSharp
FROM 'C:\Users\Kiotw\source\repos\SplitStringSharp\SplitStringSharp\bin\Debug\SplitStringSharp.dll'
WITH PERMISSION_SET = SAFE;


CREATE FUNCTION [dbo].SplitStringCLR(@text [nvarchar](max), @delimiter [nchar](1))
RETURNS TABLE (
	part nvarchar(max),
	ID_ODER int
) WITH EXECUTE AS CALLER
AS
EXTERNAL NAME SplitStringSharp.UserDefinedFunctions.SplitString

select *
from dbo.SplitStringCLR('sfdgsg;fshjgdj;aertysghd;vbxnb', ';')