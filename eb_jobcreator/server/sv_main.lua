RegisterCommand(Config.CommandName, function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    local group = xPlayer.getGroup()

    if not xPlayer then
        print('xPlayer er nil :(')
        return
    end

    if not group == Config.Group then
        Notify(source, 'Adgang nægtet. Du er ikke ' .. Config.Group, 'inform')
        return
    end

    TriggerClientEvent('eb_jobcreator:openMenu', source)
end)

lib.callback.register('eb_jobcreator:getJobs', function(source)
    local rawdata = MySQL.Sync.fetchAll('SELECT * FROM jobs')

    if rawdata then
        local jobs = {}
        for _, v in pairs(rawdata) do
            table.insert(jobs, {
                label = v.label,
                name = v.name,
            })
        end
        return jobs
    end
end)

lib.callback.register('eb_jobcreator:getJobGrades', function(source, name)
    local rawdata = MySQL.Sync.fetchAll('SELECT * FROM job_grades WHERE job_name = ? ORDER BY grade DESC', {name})

    if rawdata then
        local grades = {}
        for _, v in pairs(rawdata) do
            table.insert(grades, {
                label = v.label,
                name = v.name,
                salary = v.salary,
                number = v.grade,
            })
        end
        return grades
    end
end)

RegisterNetEvent('eb_jobcreator:deleteJob', function(name, label) 
    local xPlayer = ESX.GetPlayerFromId(source)
    local group = xPlayer.getGroup()

    if not xPlayer then
        print('xPlayer er nil :(')
        return
    end

    if not group == Config.Group then
        if Config.EnableKick then
            DropPlayer(source, Config.KickMessage)
        end
        if Logs.EnableLogs then
            local message =
            '**En spiller prøvede at slette et job uden at være admin**\n\n' ..
            '**Navn:** ' .. xPlayer.getName() .. '\n' ..
            '**Identifier:** ' .. xPlayer.getIdentifier() .. '\n' ..
            '**ID:** ' .. source .. '\n' .. 
            '**Job:** ' .. name .. '\n'
        
            DiscordLog(message)
        end
        return
    end

    MySQL.Async.execute('DELETE FROM jobs WHERE name = ?', {name})
    MySQL.Async.execute('DELETE FROM job_grades WHERE job_name = ?', {name})
    Notify(source, label .. ' blev slettet fra serveren', 'inform')
end)  

RegisterNetEvent('eb_jobcreator:addGrade', function(name, gradeData) 
    local xPlayer = ESX.GetPlayerFromId(source)
    local group = xPlayer.getGroup()
    local gradeExists = MySQL.Sync.fetchScalar('SELECT grade FROM job_grades WHERE grade = ? AND job_name = ?', {gradeData.number, name})

    if not xPlayer then
        print('xPlayer er nil :(')
        return
    end

    if not group == Config.Group then
        if Config.EnableKick then
            DropPlayer(source, Config.KickMessage)
        end
        if Logs.EnableLogs then
            local message =
            '**En spiller prøvede at tilføje et grade uden at være admin**\n\n' ..
            '**Navn:** ' .. xPlayer.getName() .. '\n' ..
            '**Identifier:** ' .. xPlayer.getIdentifier() .. '\n' ..
            '**ID:** ' .. source .. '\n' .. 
            '**Job:** ' .. name .. '\n'
        
            DiscordLog(message)
        end
        return
    end

    if gradeExists then
        Notify(source, 'Grade nummer findes allerede! ', 'inform')
        return
    end

    MySQL.Async.insert('INSERT INTO job_grades (job_name, grade, name, label, salary) VALUES (?, ?, ?, ?, ?)', {name, gradeData.number, gradeData.name, gradeData.label, gradeData.salary})
    Notify(source, gradeData.label .. ' blev tilføjet', 'inform')
end)

RegisterNetEvent('eb_jobcreator:deleteGrade', function(name, number) 
    local xPlayer = ESX.GetPlayerFromId(source)
    local group = xPlayer.getGroup()

    if not xPlayer then
        print('xPlayer er nil :(')
        return
    end

    if not group == Config.Group then
        if Config.EnableKick then
            DropPlayer(source, Config.KickMessage)
        end
        if Logs.EnableLogs then
            local message =
            '**En spiller prøvede at slette et grade uden at være admin**\n\n' ..
            '**Navn:** ' .. xPlayer.getName() .. '\n' ..
            '**Identifier:** ' .. xPlayer.getIdentifier() .. '\n' ..
            '**ID:** ' .. source .. '\n' .. 
            '**Job:** ' .. name .. '\n' .. 
            '**Grade nummer:** ' .. number .. '\n'
        
            DiscordLog(message)
        end
        return
    end

    MySQL.Async.execute('DELETE FROM job_grades WHERE job_name = ? AND grade = ?', {name, number})
    Notify(source, 'Grade ' .. number .. ' blev slettet fra serveren', 'inform')
end)



RegisterNetEvent('eb_jobcreator:updateGrade', function(name, number, gradeData)
    local xPlayer = ESX.GetPlayerFromId(source)
    local group = xPlayer.getGroup()

    if not xPlayer then
        print('xPlayer er nil :(')
        return
    end

    if not group == Config.Group then
        if Config.EnableKick then
            DropPlayer(source, Config.KickMessage)
        end
        if Logs.EnableLogs then
            local message =
            '**En spiller prøvede at opdatere et grade uden at være admin**\n\n' ..
            '**Navn:** ' .. xPlayer.getName() .. '\n' ..
            '**Identifier:** ' .. xPlayer.getIdentifier() .. '\n' ..
            '**ID:** ' .. source .. '\n' .. 
            '**Job:** ' .. name .. '\n' .. 
            '**Grade nummer:** ' .. number .. '\n'
        
            DiscordLog(message)
        end
        return
    end

    MySQL.Async.execute('UPDATE job_grades SET label = ?, name = ?, salary = ? WHERE job_name = ? AND grade = ?', {gradeData.label, gradeData.name, gradeData.salary, name, number})
    Notify(source, gradeData.label .. ' blev opdateret', 'inform')
end)  

RegisterNetEvent('eb_jobcreator:createJob', function(jobData, gradeData)
    local xPlayer = ESX.GetPlayerFromId(source)
    local group = xPlayer.getGroup()
    local exists = MySQL.Sync.fetchScalar('SELECT name FROM jobs WHERE name = ?', {jobData.name})

    if not xPlayer then
        print('xPlayer er nil :(')
        return
    end

    if not group == Config.Group then
        if Config.EnableKick then
            DropPlayer(source, Config.KickMessage)
        end
        if Logs.EnableLogs then
            local message =
            '**En spiller prøvede at tilføje et job uden at være admin**\n\n' ..
            '**Navn:** ' .. xPlayer.getName() .. '\n' ..
            '**Identifier:** ' .. xPlayer.getIdentifier() .. '\n' ..
            '**ID:** ' .. source .. '\n' .. 
            '**Job:** ' .. jobData.name .. '\n'
        
            DiscordLog(message)
        end
        return
    end

    if exists then
        Notify(source, 'Jobbet ' .. jobData.label .. ' findes allerede', 'inform')
        return
    end

    MySQL.Async.insert('INSERT INTO jobs (name, label, whitelisted) VALUES (?, ?, ?)', {jobData.name, jobData.label, jobData.whitelisted})
    for _,v in pairs(gradeData) do
        MySQL.Async.insert('INSERT INTO job_grades (job_name, grade, name, label, salary) VALUES (?, ?, ?, ?, ?)', {jobData.name, v.number, v.name, v.label, v.salary})
    end
    Notify(source, 'Du tilføjede ' .. jobData.label .. ' med ' .. #gradeData .. ' grade(s)', 'inform')
end)

function DiscordLog(message)
    local embeds = {
        {
            ["title"] = 'EB Job Creator | Exploit Logs',
            ["description"] = message,
            ["color"] = 4162294,
            ["footer"] = {
                ["text"] = "EB Scripting | https://discord.gg/CBFGCTEEAW | " .. os.date("%d/%m/%Y %H:%M:%S"),
            },
        }
    }

    PerformHttpRequest(Logs.Webhook, function(err, text, headers) end, 'POST', json.encode({ username = name, embeds = embeds }), { ['Content-Type'] = 'application/json' })
end

function Notify(id, desc, type)
    TriggerClientEvent('ox_lib:notify', id, { title = 'Job Menu', description = desc, type = type })
end
