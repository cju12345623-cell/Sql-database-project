USE [Test]
GO

/****** Object:  StoredProcedure [dbo].[RefreshCurrentData]    Script Date: 11/09/2026 16:35:50 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER   PROCEDURE [dbo].[RefreshCurrentData]
AS
BEGIN

    DROP TABLE IF EXISTS dbo.CurrentData;


    SELECT DISTINCT

        --------------------------------------------------
        -- 기본 정보
        --------------------------------------------------
        CAST(CAST(h.debitornumber AS BIGINT) AS VARCHAR(50))
            AS debitornumber,

        CAST(h.MSDProjectID AS VARCHAR(100))
            AS MSDProjectID,

        CAST(h.[Transform File.Search term] AS VARCHAR(255))
            AS CustomerName,


        --------------------------------------------------
        -- Bullfinch
        --------------------------------------------------
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM raw.Carveout c
                WHERE
                    CAST(CAST(c.debitornumber AS BIGINT) AS VARCHAR(50))
                    =
                    CAST(CAST(h.debitornumber AS BIGINT) AS VARCHAR(50))
            )
            THEN 'Bullfinch'
            ELSE NULL
        END AS Bullfinch,


        --------------------------------------------------
        -- Aging / AR
        --------------------------------------------------
        h.[To 0],
        h.[From 1 To 30],
        h.[From 31 To 60],
        h.[From 61 To 90],
        h.[From 91 To 120],
        h.[From 121],
        h.[AR Balance],


        --------------------------------------------------
        -- Ticket Status
        --------------------------------------------------
        CASE

            -- 하나라도 Open 상태 티켓이 있으면 Open
            WHEN EXISTS (
                SELECT 1
                FROM raw.Tickets t
                WHERE t.[Projekt-ID (Dynamics)] = h.MSDProjectID
                  AND LTRIM(RTRIM(t.[Ticket status])) NOT IN (
                      'Solved',
                      'Service Call',
                      'Service Call (Old)'
                  )
            )
            THEN 'Open'


            WHEN EXISTS (
                SELECT 1
                FROM raw.Tickets t
                WHERE t.[Projekt-ID (Dynamics)] = h.MSDProjectID
                  AND LTRIM(RTRIM(t.[Ticket status])) = 'Solved'
            )
            THEN 'Solved'


            WHEN EXISTS (
                SELECT 1
                FROM raw.Tickets t
                WHERE t.[Projekt-ID (Dynamics)] = h.MSDProjectID
                  AND LTRIM(RTRIM(t.[Ticket status])) = 'Service Call'
            )
            THEN 'Service Call'


            WHEN EXISTS (
                SELECT 1
                FROM raw.Tickets t
                WHERE t.[Projekt-ID (Dynamics)] = h.MSDProjectID
                  AND LTRIM(RTRIM(t.[Ticket status])) = 'Service Call (Old)'
            )
            THEN 'Service Call (Old)'


            ELSE NULL

        END AS TicketStatus,


        --------------------------------------------------
        -- Open Ticket Number 전부 합치기
        --------------------------------------------------
        (
            SELECT STRING_AGG(
                CAST(t.ID AS VARCHAR(MAX)),
                ', '
            )

            FROM raw.Tickets t

            WHERE t.[Projekt-ID (Dynamics)] = h.MSDProjectID

              AND LTRIM(RTRIM(t.[Ticket status])) NOT IN (
                  'Solved',
                  'Service Call',
                  'Service Call (Old)'
              )

        ) AS TicketNumber,


        --------------------------------------------------
        -- Default
        --------------------------------------------------
        CASE

            WHEN h.[From 31 To 60] > 0
              OR h.[From 61 To 90] > 0
              OR h.[From 91 To 120] > 0
              OR h.[From 121] > 0

            THEN 'Default'

            ELSE NULL

        END AS [Default]


    INTO dbo.CurrentData

    FROM raw.Historical h

    WHERE h.[date] = (
        SELECT MAX([date])
        FROM raw.Historical
    )

    AND h.debitornumber IS NOT NULL;
END;
GO


