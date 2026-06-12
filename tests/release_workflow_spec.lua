local harness = require("tests.TestHarness")

local function readFile(path)
  local handle = io.open(path, "r")
  if not handle then
    return nil
  end

  local contents = handle:read("*a")
  handle:close()
  return contents
end

local function assertContains(contents, needle)
  harness.assert_true(contents ~= nil)
  harness.assert_true(contents:find(needle, 1, true) ~= nil)
end

return {
  ["toc declares the 1.2.0 release version"] = function()
    local toc = readFile(harness.addon_path("RollingPinAwards.toc"))

    assertContains(toc, "## Version: 1.2.0")
  end,

  ["curseforge release workflow packages and publishes rolling pin awards"] = function()
    local workflow = readFile(".github/workflows/release-curseforge.yml")

    assertContains(workflow, "Release to CurseForge")
    assertContains(workflow, "tags:")
    assertContains(workflow, "v*")
    assertContains(workflow, "CF_PROJECT_ID")
    assertContains(workflow, "choco install lua")
    assertContains(workflow, "Find-LuaRuntime")
    assertContains(workflow, "ChocolateyInstall")
    assertContains(workflow, "ProgramFiles(x86)")
    assertContains(workflow, ".\\tests\\run.ps1")
    assertContains(workflow, ".\\tools\\release\\Build-CurseForgePackage.ps1")
    assertContains(workflow, ".\\tools\\release\\Publish-CurseForgePackage.ps1")
    assertContains(workflow, ".\\RollingPinAwards\\RollingPinAwards.toc")
  end,

  ["release scripts and documentation are present"] = function()
    assertContains(readFile("tools/release/Build-CurseForgePackage.ps1"), "RollingPinAwards-$version.zip")
    assertContains(readFile("tools/release/Build-CurseForgePackage.ps1"), "$sourceAddonRoot")
    assertContains(readFile("tools/release/Publish-CurseForgePackage.ps1"), "upload-file")
    assertContains(readFile("tools/release/Publish-CurseForgePackage.ps1"), ".\\RollingPinAwards\\RollingPinAwards.toc")
    assertContains(readFile("docs/curseforge-release-workflow.md"), "CF_PROJECT_ID")
    assertContains(readFile("docs/curseforge-description.md"), "Rolling Pin Awards")
  end,
}
