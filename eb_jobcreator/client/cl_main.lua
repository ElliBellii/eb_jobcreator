RegisterNetEvent('eb_jobcreator:openMenu')
AddEventHandler('eb_jobcreator:openMenu', function()
    lib.registerContext({
        id = 'eb_jobcreator:mainMenu',
        title = 'Server Jobs',
        options = {
            {
                title = 'Se Jobs',
                description = 'Se en liste over alle jobs på serveren',
                icon = 'list',
                onSelect = function()
                    TriggerEvent('eb_jobcreator:jobsMenu')
                end,
            },
            {
                title = 'Tilføj Job',
                description = 'Tilføj et nyt job til serveren',
                icon = 'plus',
                onSelect = function()
                    TriggerEvent('eb_jobcreator:addJob')
                end,
            },
        }
    })
    lib.showContext('eb_jobcreator:mainMenu')
end)

AddEventHandler('eb_jobcreator:jobsMenu', function()
    local jobs = lib.callback.await('eb_jobcreator:getJobs', false)

    if not jobs then
        print('callback er nil :(')
        return
    end

    local options = {}

    if #jobs > 0 then
        for _,v in pairs(jobs) do
            table.insert(options, {
                title = v.label,
                description = 'Klik for at redigere ' .. v.label,
                icon = 'briefcase',
                onSelect = function()
                    TriggerEvent('eb_jobcreator:jobGradesMenu', v.name, v.label)
                end,
            })
        end
    else
        table.insert(options, {
            title = 'Ingen jobs fundet',
            readOnly = true,
        })
    end

    lib.registerContext({
        id = 'eb_jobcreator:jobsMenu',
        title = 'Jobliste',
        menu = 'eb_jobcreator:mainMenu',
        options = options
    })
    lib.showContext('eb_jobcreator:jobsMenu')
end)

AddEventHandler('eb_jobcreator:jobGradesMenu', function(name, label)
    local grades = lib.callback.await('eb_jobcreator:getJobGrades', false, name)

    if not grades then
        print('callback er nil :(')
        return
    end

    local options = {
        {
            title = 'Slet Job',
            description = 'Slet ' .. label .. ' fra serveren',
            icon = 'minus',
            onSelect = function()
                local alert = lib.alertDialog({
                    header = 'Bekræftelse',
                    content = 'Job: **' .. label .. '**\n\nØnsker du at slette dette job?',
                    centered = true,
                    cancel = true
                })

                if alert == 'confirm' then
                    TriggerServerEvent('eb_jobcreator:deleteJob', name, label)
                else
                    lib.showContext('eb_jobcreator:jobGradesMenu')
                end
            end,    
        },
        {
            title = 'Tilføj Grade',
            description = 'Tilføj et nyt grade til ' .. label,
            icon = 'plus',
            onSelect = function()
                local input = lib.inputDialog('Tilføj Grade', {
                    {type = 'input', label = 'Grade Label', required = true},
                    {type = 'input', label = 'Grade Navn', required = true},
                    {type = 'number', label = 'Grade Nummer', required = true},
                    {type = 'number', label = 'Grade Løn', required = true},
                })
                if not input then lib.showContext('eb_jobcreator:jobGradesMenu') return end

                local gradeData = {
                    label = input[1],
                    name = input[2],
                    number = input[3],
                    salary = input[4],
                }
                TriggerServerEvent('eb_jobcreator:addGrade', name, gradeData)
                lib.showContext('eb_jobcreator:mainMenu')
            end,
        },
        {
            title = '',
            readOnly = true,
        },
    }

    if #grades > 0 then
        for _,v in pairs(grades) do
            table.insert(options, {
                title = v.number .. ' | ' .. v.label,
                description = 'Løn: ' .. ESX.Math.GroupDigits(v.salary) .. ',-',
                icon = 'user',
                onSelect = function()
                    local input = lib.inputDialog(v.number .. ' | ' .. v.label, {
                        {type = 'input', label = 'Grade Label', default = v.label, required = true},
                        {type = 'input', label = 'Grade Navn', default = v.name, required = true},
                        {type = 'number', label = 'Grade Løn', default = v.salary, required = true},
                        {type = 'checkbox', label = 'Slet Grade'},
                    })
                    if not input then lib.showContext('eb_jobcreator:jobGradesMenu') return end
                    if input[4] then
                        local alert = lib.alertDialog({
                            header = 'Bekræftelse',
                            content = 'Grade: **' .. v.number .. ' - ' .. v.label .. '**\n\nØnsker du at slette denne grade?',
                            centered = true,
                            cancel = true
                        })
        
                        if alert == 'confirm' then
                            TriggerServerEvent('eb_jobcreator:deleteGrade', name, v.number)
                        else
                            lib.showContext('eb_jobcreator:jobGradesMenu')
                        end
                    else
                        local gradeData = {
                            label = input[1],
                            name = input[2],
                            salary = input[3],
                        }
                        TriggerServerEvent('eb_jobcreator:updateGrade', name, v.number, gradeData)
                    end
                end,
            })
        end
    else
        table.insert(options, {
            title = 'Ingen grades fundet',
            readOnly = true,
        })
    end

    lib.registerContext({
        id = 'eb_jobcreator:jobGradesMenu',
        title = label .. ' Grades',
        menu = 'eb_jobcreator:jobsMenu',
        options = options
    })
    lib.showContext('eb_jobcreator:jobGradesMenu')
end)

AddEventHandler('eb_jobcreator:addJob', function()
    local input = lib.inputDialog('Tilføj Job', {
        {type = 'input', label = 'Job Label', required = true},
        {type = 'input', label = 'Job Navn', required = true},
        {type = 'select', label = 'Whitelisted', required = true, options = {
            {value = 0, label = 'Nej'},
            {value = 1, label = 'Ja'},
        }},
        {type = 'number', label = 'Antal Grades', min = 1, required = true},
    })
    if not input then lib.showContext('eb_jobcreator:mainMenu') return end

    local jobData = {
        label = input[1],
        name = input[2],
        whitelisted = input[3],
        grades = input[4],
    }

    local gradeData = {}
    local gradeCount = 0

    repeat
        local input = lib.inputDialog('Grade ' .. gradeCount, {
            {type = 'input', label = 'Grade Label', required = true},
            {type = 'input', label = 'Grade Navn', required = true},
            {type = 'number', label = 'Grade Løn', required = true},
        })
        if not input then lib.showContext('eb_jobcreator:jobsMenu') return end

        table.insert(gradeData, {
            label = input[1],
            name = input[2],
            salary = input[3],
            number = gradeCount,
        })
        gradeCount = gradeCount+1
    until gradeCount == jobData.grades

    TriggerServerEvent('eb_jobcreator:createJob', jobData, gradeData)
end)
