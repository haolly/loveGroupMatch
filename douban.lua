--程序说明：
--1，每个匹配项都有一个权重，权重越大，对最后计算的分数影响越大。例如三观的权重应该比较大一点
--2，只支持男女匹配，其他类型的超出我的能力范围，sorry
--3，除了问卷中有涉及的明确匹配要求的项目，例如身高，其他项目的计分方法严重带有自己的个人色彩。例如我认为学历不是很重要，所以权重设置为5
--4，注意，和你最匹配的那个人，对ta来说，你不一定就是ta最匹配的人。所以不要想着等ta来主动找你，你需要主动出击！

--修改说明：
-- 添加新列需要做的事情：
-- 1，在 tbColumnName 里面添加新的列名字，顺序要和 输入文件(txt 文件)的列顺序一致, 输入文件中这一列的内容不能为空
-- 2，在 如果这个列你们的内容是数字，将这个列名添加到 tbNumberColumnName 里面，顺序不重要
-- 3，在 tbWeight 里面添加新列的权重
-- 4，添加新的积分函数，格式为 Judge_XXX, 其中 XXX 就是列名，可以参考其他 Judge 函数的写法
-- 5, 同一个条件只需要添加一个积分函数即可，例如 education 和 educationRequire ，只需要添加一个 Judge 积分函数即可
---------------------------------------分割线----------------------------------------------

local tbData = {
}

local tbColumnName = {
    "id",
    "sex",
    "age",
    "acceptAgeHigh",
    "acceptAgeLow",
    "nativePlace",
    "liveInZhuHai",
    "height",
    "acceptHeightLow",
    "acceptHeightHigh",
    "bodyType",
    "bodyTypeRequire",
    "salaryK",
    "salary",
    "salaryExpect",
    "hobby",
    "preferLoveProcess",
    "character",
    "characterRequire",
    "moneyView",
    "sexView",
    "relationView",
    "face",
    "faceRequire",
    "education",
    "educationRequire",
    "location",
}

--哪些列的名字内容是数字
local tbNumberColumnName = {
    "age",
    "acceptAgeHigh",
    "acceptAgeLow",
    "liveInZhuHai",
    "height",
    "acceptHeightLow",
    "acceptHeightHigh",
    "salaryK",
    "preferLoveProcess",
    "moneyView",
    "sexView",
    "face",
    "faceRequire",
    "education",
    "educationRequire",
}

--每一项匹配计算的权重，最高为10，最低为1, 默认为1
local tbWeight = {
    age = 4,
    nativePlace = 2,
    liveInZhuHai = 7,
    height = 5,
    bodyType = 8,
    salaryK = 6,
    hobby = 5,
    preferLoveProcess = 5,
    character = 4,
    moneyView = 9,
    sexView = 10,
    relationView = 8,
    education = 5,
    face = 6,
}

--需要补充类似的爱好
local analogyWords = {
    {"阅读", "看书", "看小说", "书", "小说", "写作", "话剧"},
    {"美剧", "英剧", "看美剧", "看英剧", "电影", "看电影", "韩剧", "日剧", "剧"},
    {"素描", "绘画", "画画"},
    {"足球", "游泳", "踢足球", "篮球", "打篮球", "网球", "打网球", "羽毛球", "打羽毛球", "慢跑", "跑步", "健身", "瑜伽", "轮滑"},
    {"桌游", "狼人杀", "三国杀"},
    {"泡吧", "喝酒",},
    {"八卦", "聊天"},
    {"唱歌", "音乐", "听歌", "聊天"},
    {"徒步", "户外", "爬山", "自行车", "骑车"},
    {"摄影", "旅行", "潜水"},
    {"美食", "吃", "宅", "做饭"},
    {"民谣"},
    {"游戏", "lol"},
    {"看海"}
}

--最后打印出每个人的 top 前几匹配人信息
local topOfMatchForPrint = 2
local outputFileName = "doubanLoveGroupLoveMatch.csv"
local inputFileName = "douban2.txt"
local debugOn = false

---------------------------------------分割线----------------------------------------------

old_print = print
print = function(...)
    --local calling_script = debug.getinfo(2).short_src
    --old_print('Print called by: '..calling_script)
    if(debugOn) then
        old_print(...)
    end
end

local tbUtils = {}
function tbUtils:Contains(tbSet, item)
    for k,v in ipairs(tbSet) do
        if(v == item) then
            return true
        end
    end
    return false
end

function tbUtils:IntersectNum(tbSetSelf, tbSetOther)
    local res = 0
    for k,v in ipairs(tbSetSelf) do
        if(self:Contains(tbSetOther, v)) then
            res = res + 1
        end
    end
    return res
end

function tbUtils:GetAnalogyTable(item)
    local res = {}
    for _, v in ipairs(analogyWords) do
        if(self:Contains(v, item)) then
            return v
        end
    end
    table.insert(res, 1, item)
    return res
end

function tbUtils:IntersectNumWithRespectAnalogy(tbSetSelf, tbSetOther)
    local intersect = 0
    for k,v in ipairs(tbSetSelf) do
        local tbAnalogy = self:GetAnalogyTable(v)
        for _, item in ipairs(tbAnalogy) do
            repeat
                if(self:Contains(tbSetOther, item)) then
                    intersect = intersect + 1
                    break
                end
            until true
        end
    end
    return intersect
end

function tbUtils:PrintTitle()
    local tbSample = tbColumnName
    for k,v in ipairs(tbSample) do
        io.write(tostring(v) .. "\t")
    end
    io.write("\n")
end

function tbUtils:PrintPerson(person, score)
    for _,col in ipairs(tbColumnName) do
        local v = person[col]
        if(type(v) == "table") then
            io.write("[")
            for k,v in ipairs(v) do
                io.write(tostring(v) .. ",")
            end
            io.write("]\t")
        else
            io.write(tostring(v) .. "\t")
        end
    end
    io.write(score)
    io.write("\n")
end

function tbUtils:mysplit(inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={} ; i=1
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                t[i] = str
                i = i + 1
        end
        return t
end

function tbUtils:ParseOnePerson(line)
    local tbRaw = self:mysplit(line, '\t')
    local tbPerson = {}
    local i = 1
    for k,v in ipairs(tbColumnName) do
        if(self:Contains(tbNumberColumnName, v)) then
            tbPerson[v] = tonumber(tbRaw[i])
        else
            tbPerson[v] = tbRaw[i]
        end
        print("column:value", v, tbPerson[v])
        i = i+1
    end
    return tbPerson
end

---------------------------------------分割线----------------------------------------------

local zhuHaiLoveGroup = {}

function zhuHaiLoveGroup:SetUp()
    local fileName = inputFileName
    for line in io.lines(fileName) do
        local tbPerson = tbUtils:ParseOnePerson(line)
        tbData[#tbData + 1] = tbPerson
    end
end

function zhuHaiLoveGroup:Judge_sex(you, other)
    local res = 0
    if(you == other) then
        res = -1000000
    end
    return res
end

function zhuHaiLoveGroup:Judge_age(you, other, tbPerson, tbPersonOther)
    local res = 0
    local min = tbPerson.acceptAgeLow
    local max = tbPerson.acceptAgeHigh
    if(other >= min and other <= max) then
        res = 10
    elseif(other - min <= 1) then
        res = 2
    elseif(other - max >= 1) then
        res = 2
    end
    return res
end

-- function zhuHaiLoveGroup:Judge_age(you, other, tbPerson, tbPersonOther)
--     local res = 0
--     if(tbPerson.sex == "" and tbPersonOther.sex == "female") then
--         if(you >= other) then
--             res = 10
--         elseif(other - you <= 1) then
--             res = 5
--         elseif(other - you <= 2) then
--             res = 3
--         elseif(other - you <= 3) then
--             res = 1
--         end
--     elseif(tbPerson.sex == "female" and tbPersonOther.sex == "male") then
--         if(you > other) then
--             res = 0
--         elseif(other - you <= 1) then
--             res = 10
--         elseif(other - you <= 3) then
--             res = 5
--         elseif(other - you <= 5) then
--             res = 3
--         elseif(other - you <= 8) then
--             res = 1
--         end
--     end
--     return res
-- end

function zhuHaiLoveGroup:Judge_nativePlace(you, other)
    local res = 0
    if(you == other) then
        res = 10
    end
    return res
end

function zhuHaiLoveGroup:Judge_liveInZhuHai(you, other)
    local res = 0
    if(you == 1 and other == 1) then
        res = 10
    elseif (you == 3 or other == 3) then
        res = 3
    end
    return res
end

function zhuHaiLoveGroup:Judge_height(you, other, tbPerson, tbPersonOther)
    local res = 0
    local min = tbPerson.acceptHeightLow
    local max = tbPerson.acceptHeightHigh
    if(other >= min and other <= max) then
        res = 10
    elseif(min - other <= 5) then
        res = 2
    elseif(other - max <= 5) then
        res = 2
    end
    return res
end

-- function zhuHaiLoveGroup:Judge_height(you, other, tbPersonYou, tbPersonOther)
--     local res = 0
--     if(tbPerson.sex == "male" and tbPersonOther.sex == "female") then
--         if(you >= other and (you - other >=20)) then
--             res = 5
--         elseif(you >= other and (you - other >= 15)) then
--             res = 8
--         elseif(you >= other) then
--             res = 10
--         elseif(other - you <= 5) then
--             res = 3
--         end
--     elseif(tbPerson.sex == "female" and tbPersonOther.sex == "male") then
--         if(other >= you and (other - you >= 5)) then
--             res = 10
--         elseif(other >= you) then
--             res = 5
--         end
--     end
--     return res
-- end

function zhuHaiLoveGroup:Judge_bodyType(you, other, tbPerson, tbPersonOther)
    local res = 0
    local expect = tbPerson.bodyTypeRequire
    local tbExpect = tbUtils:mysplit(expect,'|')
    if(tbUtils:Contains(tbExpect, other)) then
        res = 10
    end
    return res
end

-- function zhuHaiLoveGroup:Judge_bodyType(you, other, tbPerson, tbPersonOther)
--     local res = 0
--     if(you == other) then
--         res = 10
--     elseif((you == 1) and (tbPerson.sex == "female")) then
--         res = 8
--     end
--     return res
-- end

function zhuHaiLoveGroup:Judge_salaryK(you, other, tbPerson, tbPersonOther)
    local you = tonumber(you)
    local other = tonumber(other)
    local res = 0
    if(tbPerson.sex == "男") then
        if(you >= 10) then
            if(you - other >= 8) then
                res = 2
            elseif(you - other >= 5) then
                res = 10
            elseif(you >= other) then
                res = 6
            end
        else
            if(you - other >= 8) then
                res = 2
            elseif(you - other >= 5) then
                res = 5
            elseif(you >= other) then
                res = 10
            end
        end
    elseif(tbPerson.sex == "女") then
        if(you >= 10) then
            if(other - you >= 8) then
                res = 5
            elseif(other - you >= 5) then
                res = 8
            elseif(other >= you ) then
                res = 7
            elseif(you > other) then
                res = 1
            end
        else
            if(other - you >= 8) then
                res = 2
            elseif(other - you >= 5) then
                res = 7
            elseif(other >= you ) then
                res = 8
            elseif(you > other) then
                res = 0
            end
        end
    end
    if(you >= 50) then
        res = -999
    end
    return res
end

function zhuHaiLoveGroup:Judge_hobby(you, other)
    local res = 0
    local common = 0
    for k,v in ipairs(analogyWords) do
        for _, hobby in ipairs(v) do
            if(string.find(you, hobby) and string.find(other, hobby)) then
                common = common + 1
            end
        end
    end
    if(common == 1) then
        res = 4
    elseif(common == 2) then
        res = 7
    elseif(common > 2) then
        res = 10
    end
    return res
end

-- function zhuHaiLoveGroup:Judge_hobby(you, other)
--     local res = 0
--     local intersect = tbUtils:IntersectNumWithRespectAnalogy(you, other)
--     if(#you == #other) then
--         res = ( intersect / #you * 10)
--     else
--         local minLength = math.min( #you, #other)
--         res = (intersect / minLength * 9)
--     end
--     return res
-- end

function zhuHaiLoveGroup:Judge_preferLoveProcess(you, other)
    local res = 0
    if you == other then
        res = 10
    elseif ((you == 1 and other == 2 ) or (you == 3 and other == 4)) then
        res = 7
    else
        res = 3
    end
    return res
end

function zhuHaiLoveGroup:Judge_character(you, other, tbPerson, tbPersonOther)
    local res = 0
    local expect = tbPerson.characterRequire
    local tbExpect = tbUtils:mysplit(expect, '|')
    local tbOther = tbUtils:mysplit(other, '|')
    local intersect = tbUtils:IntersectNum(tbExpect, tbOther)
    if(intersect >= 3) then
        res = 10
    elseif(intersect >= 2) then
        res = 7
    elseif(intersect >= 1) then
        res = 4
    else
        res = 1
    end
    return res
end

function zhuHaiLoveGroup:Judge_moneyView(you, other, tbPerson, tbPersonOther)
    local res = 0
    if(you == other) then
        res = 10
    elseif(tbPerson.sex == "女") then
        if(you == 1) then
            res = 1
        else
            res = 3
        end
    end
    return res
end

function zhuHaiLoveGroup:Judge_sexView(you, other)
    local res = 0
    if(you == other) then
        res = 10
    end
    return res
end

function zhuHaiLoveGroup:Judge_relationView(you, other, tbPerson, tbPersonOther)
    local res = 0
    local tbYou = tbUtils:mysplit(you, '|')
    local tbOther = tbUtils:mysplit(other, '|')
    local intersect = tbUtils:IntersectNum(tbYou, tbOther)
    if(intersect >= 3) then
        res = 10
    elseif(intersect >= 2) then
        res = 8
    elseif(intersect >= 1) then
        res = 5
    end
    return res
end

function zhuHaiLoveGroup:Judge_face(you, other, tbPerson, tbPersonOther)
    local res = 0
    local require = tbPerson.faceRequire
    local gender = tbPerson.sex
    local highRequire = false
    if(require - you >= 2) then
        highRequire = true
    end
    if(gender == "男") then
        if(require == 4) then
            if(other == 4) then
                res = 10
            elseif(other == 3) then
                res = 5
            else
                res = 1
            end
        elseif(other >= require) then
            res = 10
        else
            res = 1
        end
    else
        if(require == 4) then
            if(other == 4) then
                res = 10
            elseif(other == 3) then
                res = 8
            elseif(other == 2) then
                res = 3
            elseif(other == 1) then
                res = 1
            end
        elseif(other >= require) then
            res = 10
        else
            res = 1
        end
    end
    if(highRequire) then
        res = res * 0.5
    end
    return res
end

function zhuHaiLoveGroup:Judge_education(you, other, tbPerson, tbPersonOther)
    print("you", you)
    print("other", other)
    print("id", tbPerson.id)
    local require = tbPerson.educationRequire
    print("require", require)
    local res = 0
    if(you == 0) then
        res = 10
    elseif(other >= require) then
        res = 10
    elseif(require - other == 1) then
        res = 5
    else
        res = 3
    end
    return res
end

function zhuHaiLoveGroup:HaveJudgeFunc(field)
    local func = self["Judge_" .. field]
    if func == nil then
        return false
    elseif type(func) == "function" then
        return true, func
    end
end

function zhuHaiLoveGroup:CalculateScore(tbPerson, tbData)
    local tbResForPerson = {}
    for _, otherPerson in ipairs(tbData) do
        repeat
            if(otherPerson.id == tbPerson.id) then
                break
            end
            local tbSinglePersonRes = {}
            local score = 0
            for k, v in pairs(tbPerson) do
                local haveJudgeFunc, func = self:HaveJudgeFunc(k)
                local weight = tbWeight[k]
                if(weight == nil) then
                    --print("not find weight for ", k)
                    weight = 1
                end
                if haveJudgeFunc then
                    score = score + math.floor(func(self, v, otherPerson[k], tbPerson, otherPerson) * weight)
                else
                    --print("not find judge func for ", k)
                end
            end
            tbSinglePersonRes.score = score
            tbSinglePersonRes.person = otherPerson
            tbResForPerson[#tbResForPerson + 1] = tbSinglePersonRes
        until true
    end
    table.sort( tbResForPerson,
        function(item0, item1)
            if(item0.score > item1.score) then
                return true
            else
                return false
            end
        end
    )
    return tbResForPerson
end

function zhuHaiLoveGroup:PrintResult(tbResForPerson)
    for k,v in ipairs(tbResForPerson) do
        if(k > topOfMatchForPrint) then
            break
        end
        tbUtils:PrintPerson(v.person, v.score)
    end
end

function zhuHaiLoveGroup:StartMatch()
    self:SetUp()
    file = io.open(outputFileName, "w+")
    io.output(file)
    tbUtils:PrintTitle()
    for _, person in ipairs(tbData) do
        local tbMatchRes = self:CalculateScore(person, tbData)
        io.write("MatchResultFor ", person.id, "\n")
        self:PrintResult(tbMatchRes)
    end
    io.close(file)
end

zhuHaiLoveGroup:StartMatch()
