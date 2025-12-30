# Third-Party Licenses

This document contains the licensing information and acknowledgments for all third-party
dependencies used in the Octopus Agile Dashboard project.

**Last Updated:** 2025-12-30

---

## Table of Contents

1. [License Summary](#license-summary)
2. [License Compatibility Analysis](#license-compatibility-analysis)
3. [Frontend Dependencies](#frontend-dependencies)
4. [Backend Dependencies](#backend-dependencies)
5. [Development Dependencies](#development-dependencies)
6. [Full License Texts](#full-license-texts)

---

## License Summary

### Overview

| License Type | Count | Attribution Required | Copyleft |
|--------------|-------|---------------------|----------|
| MIT | 35 | Yes | No |
| BSD-3-Clause | 5 | Yes | No |
| Apache-2.0 | 4 | Yes | No |
| ISC | 1 | Yes | No |

### Key Findings

- **No copyleft licenses detected** - All dependencies use permissive open-source licenses
- **No license incompatibilities** - All licenses are compatible with each other and with commercial use
- **Attribution required** - All licenses require copyright notices be preserved in distributions

---

## License Compatibility Analysis

### Compatibility Matrix

All licenses used in this project are **permissive** and **compatible** with:
- Commercial/proprietary distribution
- Open-source distribution under any license
- Each other (MIT, BSD, Apache 2.0, ISC are all compatible)

### Distribution Requirements

When distributing this software (source or binary), you must:

1. **Include copyright notices** for all dependencies
2. **Include license texts** (this document satisfies this requirement)
3. **For Apache 2.0 licensed code**: Include NOTICE file if the original project provides one
4. **Do NOT claim endorsement** by original authors without permission

### Concerns for Public Release

| Concern | Status | Notes |
|---------|--------|-------|
| Copyleft (GPL/LGPL) | **None Found** | Safe for proprietary distribution |
| License Incompatibility | **None Found** | All licenses are compatible |
| Attribution Requirements | **Action Required** | Include this file in distributions |
| Patent Clauses | **Low Risk** | Apache 2.0 includes patent grant |

---

## Frontend Dependencies

### Production Dependencies

| Library | Version | License | Attribution Required |
|---------|---------|---------|---------------------|
| [@tanstack/react-query](https://github.com/TanStack/query) | ^5.62.16 | MIT | Yes |
| [ag-grid-community](https://github.com/ag-grid/ag-grid) | ^31.3.4 | MIT | Yes |
| [ag-grid-react](https://github.com/ag-grid/ag-grid) | ^31.3.4 | MIT | Yes |
| [axios](https://github.com/axios/axios) | ^1.7.9 | MIT | Yes |
| [clsx](https://github.com/lukeed/clsx) | ^2.1.1 | MIT | Yes |
| [date-fns](https://github.com/date-fns/date-fns) | ^3.6.0 | MIT | Yes |
| [lucide-react](https://github.com/lucide-icons/lucide) | ^0.468.0 | ISC | Yes |
| [plotly.js](https://github.com/plotly/plotly.js) | ^2.35.3 | MIT | Yes |
| [react](https://github.com/facebook/react) | ^18.3.1 | MIT | Yes |
| [react-dom](https://github.com/facebook/react) | ^18.3.1 | MIT | Yes |
| [react-plotly.js](https://github.com/plotly/react-plotly.js) | ^2.6.0 | MIT | Yes |

### Development Dependencies

| Library | Version | License | Attribution Required |
|---------|---------|---------|---------------------|
| [@eslint/js](https://github.com/eslint/eslint) | ^9.17.0 | MIT | Yes |
| [@types/react](https://github.com/DefinitelyTyped/DefinitelyTyped) | ^18.3.18 | MIT | Yes |
| [@types/react-dom](https://github.com/DefinitelyTyped/DefinitelyTyped) | ^18.3.5 | MIT | Yes |
| [@types/react-plotly.js](https://github.com/DefinitelyTyped/DefinitelyTyped) | ^2.6.3 | MIT | Yes |
| [@vitejs/plugin-react](https://github.com/vitejs/vite-plugin-react) | ^4.3.4 | MIT | Yes |
| [autoprefixer](https://github.com/postcss/autoprefixer) | ^10.4.20 | MIT | Yes |
| [eslint](https://github.com/eslint/eslint) | ^9.17.0 | MIT | Yes |
| [eslint-config-prettier](https://github.com/prettier/eslint-config-prettier) | ^10.1.8 | MIT | Yes |
| [eslint-plugin-react-hooks](https://github.com/facebook/react) | ^5.1.0 | MIT | Yes |
| [eslint-plugin-react-refresh](https://github.com/ArnaudBarre/eslint-plugin-react-refresh) | ^0.4.16 | MIT | Yes |
| [globals](https://github.com/sindresorhus/globals) | ^15.14.0 | MIT | Yes |
| [postcss](https://github.com/postcss/postcss) | ^8.4.49 | MIT | Yes |
| [prettier](https://github.com/prettier/prettier) | ^3.7.4 | MIT | Yes |
| [tailwindcss](https://github.com/tailwindlabs/tailwindcss) | ^3.4.17 | MIT | Yes |
| [typescript](https://github.com/microsoft/TypeScript) | ^5.7.2 | Apache-2.0 | Yes |
| [typescript-eslint](https://github.com/typescript-eslint/typescript-eslint) | ^8.18.2 | MIT | Yes |
| [vite](https://github.com/vitejs/vite) | ^6.2.0 | MIT | Yes |

---

## Backend Dependencies

### Production Dependencies

| Library | Version | License | Attribution Required |
|---------|---------|---------|---------------------|
| [fastapi](https://github.com/tiangolo/fastapi) | 0.115.6 | MIT | Yes |
| [uvicorn](https://github.com/encode/uvicorn) | 0.34.0 | BSD-3-Clause | Yes |
| [pydantic](https://github.com/pydantic/pydantic) | 2.10.4 | MIT | Yes |
| [pydantic-settings](https://github.com/pydantic/pydantic-settings) | 2.7.0 | MIT | Yes |
| [httpx](https://github.com/encode/httpx) | 0.28.1 | BSD-3-Clause | Yes |
| [sqlalchemy](https://github.com/sqlalchemy/sqlalchemy) | 2.0.36 | MIT | Yes |
| [asyncpg](https://github.com/MagicStack/asyncpg) | 0.30.0 | Apache-2.0 | Yes |
| [alembic](https://github.com/sqlalchemy/alembic) | 1.14.0 | MIT | Yes |
| [redis](https://github.com/redis/redis-py) | 5.2.1 | MIT | Yes |
| [python-dotenv](https://github.com/theskumar/python-dotenv) | 1.0.1 | BSD-3-Clause | Yes |
| [python-dateutil](https://github.com/dateutil/dateutil) | 2.9.0.post0 | Apache-2.0 / BSD-3-Clause | Yes |

### Development Dependencies

| Library | Version | License | Attribution Required |
|---------|---------|---------|---------------------|
| [pytest](https://github.com/pytest-dev/pytest) | 8.3.4 | MIT | Yes |
| [pytest-asyncio](https://github.com/pytest-dev/pytest-asyncio) | 0.24.0 | Apache-2.0 | Yes |
| [pytest-cov](https://github.com/pytest-dev/pytest-cov) | 6.0.0 | MIT | Yes |
| [black](https://github.com/psf/black) | 24.10.0 | MIT | Yes |
| [isort](https://github.com/PyCQA/isort) | 5.13.2 | MIT | Yes |
| [mypy](https://github.com/python/mypy) | 1.13.0 | MIT | Yes |
| [ruff](https://github.com/astral-sh/ruff) | 0.8.4 | MIT | Yes |
| [types-python-dateutil](https://github.com/python/typeshed) | 2.9.0.20241206 | Apache-2.0 | Yes |
| [pip-tools](https://github.com/jazzband/pip-tools) | 7.4.1 | BSD-3-Clause | Yes |
| [pre-commit](https://github.com/pre-commit/pre-commit) | 4.0.1 | MIT | Yes |

---

## Full License Texts

### MIT License

The following packages are licensed under the MIT License:

**Frontend:** @tanstack/react-query, ag-grid-community, ag-grid-react, axios, clsx, date-fns,
plotly.js, react, react-dom, react-plotly.js, @eslint/js, @types/react, @types/react-dom,
@types/react-plotly.js, @vitejs/plugin-react, autoprefixer, eslint, eslint-config-prettier,
eslint-plugin-react-hooks, eslint-plugin-react-refresh, globals, postcss, prettier, tailwindcss,
typescript-eslint, vite

**Backend:** fastapi, pydantic, pydantic-settings, sqlalchemy, alembic, redis, pytest, pytest-cov,
black, isort, mypy, ruff, pre-commit

```
MIT License

Copyright (c) [year] [copyright holders]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

### BSD 3-Clause License

The following packages are licensed under the BSD 3-Clause License:

**Backend:** uvicorn, httpx, python-dotenv, python-dateutil (dual-licensed), pip-tools

```
BSD 3-Clause License

Copyright (c) [year] [copyright holders]
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

---

### Apache License 2.0

The following packages are licensed under the Apache License 2.0:

**Frontend:** typescript

**Backend:** asyncpg, python-dateutil (dual-licensed), pytest-asyncio, types-python-dateutil

```
                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

   TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

   1. Definitions.

      "License" shall mean the terms and conditions for use, reproduction,
      and distribution as defined by Sections 1 through 9 of this document.

      "Licensor" shall mean the copyright owner or entity authorized by
      the copyright owner that is granting the License.

      "Legal Entity" shall mean the union of the acting entity and all
      other entities that control, are controlled by, or are under common
      control with that entity. For the purposes of this definition,
      "control" means (i) the power, direct or indirect, to cause the
      direction or management of such entity, whether by contract or
      otherwise, or (ii) ownership of fifty percent (50%) or more of the
      outstanding shares, or (iii) beneficial ownership of such entity.

      "You" (or "Your") shall mean an individual or Legal Entity
      exercising permissions granted by this License.

      "Source" form shall mean the preferred form for making modifications,
      including but not limited to software source code, documentation
      source, and configuration files.

      "Object" form shall mean any form resulting from mechanical
      transformation or translation of a Source form, including but
      not limited to compiled object code, generated documentation,
      and conversions to other media types.

      "Work" shall mean the work of authorship, whether in Source or
      Object form, made available under the License, as indicated by a
      copyright notice that is included in or attached to the work
      (an example is provided in the Appendix below).

      "Derivative Works" shall mean any work, whether in Source or Object
      form, that is based on (or derived from) the Work and for which the
      editorial revisions, annotations, elaborations, or other modifications
      represent, as a whole, an original work of authorship. For the purposes
      of this License, Derivative Works shall not include works that remain
      separable from, or merely link (or bind by name) to the interfaces of,
      the Work and Derivative Works thereof.

      "Contribution" shall mean any work of authorship, including
      the original version of the Work and any modifications or additions
      to that Work or Derivative Works thereof, that is intentionally
      submitted to the Licensor for inclusion in the Work by the copyright owner
      or by an individual or Legal Entity authorized to submit on behalf of
      the copyright owner. For the purposes of this definition, "submitted"
      means any form of electronic, verbal, or written communication sent
      to the Licensor or its representatives, including but not limited to
      communication on electronic mailing lists, source code control systems,
      and issue tracking systems that are managed by, or on behalf of, the
      Licensor for the purpose of discussing and improving the Work, but
      excluding communication that is conspicuously marked or otherwise
      designated in writing by the copyright owner as "Not a Contribution."

      "Contributor" shall mean Licensor and any individual or Legal Entity
      on behalf of whom a Contribution has been received by Licensor and
      subsequently incorporated within the Work.

   2. Grant of Copyright License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      copyright license to reproduce, prepare Derivative Works of,
      publicly display, publicly perform, sublicense, and distribute the
      Work and such Derivative Works in Source or Object form.

   3. Grant of Patent License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      (except as stated in this section) patent license to make, have made,
      use, offer to sell, sell, import, and otherwise transfer the Work,
      where such license applies only to those patent claims licensable
      by such Contributor that are necessarily infringed by their
      Contribution(s) alone or by combination of their Contribution(s)
      with the Work to which such Contribution(s) was submitted. If You
      institute patent litigation against any entity (including a
      cross-claim or counterclaim in a lawsuit) alleging that the Work
      or a Contribution incorporated within the Work constitutes direct
      or contributory patent infringement, then any patent licenses
      granted to You under this License for that Work shall terminate
      as of the date such litigation is filed.

   4. Redistribution. You may reproduce and distribute copies of the
      Work or Derivative Works thereof in any medium, with or without
      modifications, and in Source or Object form, provided that You
      meet the following conditions:

      (a) You must give any other recipients of the Work or
          Derivative Works a copy of this License; and

      (b) You must cause any modified files to carry prominent notices
          stating that You changed the files; and

      (c) You must retain, in the Source form of any Derivative Works
          that You distribute, all copyright, patent, trademark, and
          attribution notices from the Source form of the Work,
          excluding those notices that do not pertain to any part of
          the Derivative Works; and

      (d) If the Work includes a "NOTICE" text file as part of its
          distribution, then any Derivative Works that You distribute must
          include a readable copy of the attribution notices contained
          within such NOTICE file, excluding those notices that do not
          pertain to any part of the Derivative Works, in at least one
          of the following places: within a NOTICE text file distributed
          as part of the Derivative Works; within the Source form or
          documentation, if provided along with the Derivative Works; or,
          within a display generated by the Derivative Works, if and
          wherever such third-party notices normally appear. The contents
          of the NOTICE file are for informational purposes only and
          do not modify the License. You may add Your own attribution
          notices within Derivative Works that You distribute, alongside
          or as an addendum to the NOTICE text from the Work, provided
          that such additional attribution notices cannot be construed
          as modifying the License.

      You may add Your own copyright statement to Your modifications and
      may provide additional or different license terms and conditions
      for use, reproduction, or distribution of Your modifications, or
      for any such Derivative Works as a whole, provided Your use,
      reproduction, and distribution of the Work otherwise complies with
      the conditions stated in this License.

   5. Submission of Contributions. Unless You explicitly state otherwise,
      any Contribution intentionally submitted for inclusion in the Work
      by You to the Licensor shall be under the terms and conditions of
      this License, without any additional terms or conditions.
      Notwithstanding the above, nothing herein shall supersede or modify
      the terms of any separate license agreement you may have executed
      with Licensor regarding such Contributions.

   6. Trademarks. This License does not grant permission to use the trade
      names, trademarks, service marks, or product names of the Licensor,
      except as required for reasonable and customary use in describing the
      origin of the Work and reproducing the content of the NOTICE file.

   7. Disclaimer of Warranty. Unless required by applicable law or
      agreed to in writing, Licensor provides the Work (and each
      Contributor provides its Contributions) on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
      implied, including, without limitation, any warranties or conditions
      of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
      PARTICULAR PURPOSE. You are solely responsible for determining the
      appropriateness of using or redistributing the Work and assume any
      risks associated with Your exercise of permissions under this License.

   8. Limitation of Liability. In no event and under no legal theory,
      whether in tort (including negligence), contract, or otherwise,
      unless required by applicable law (such as deliberate and grossly
      negligent acts) or agreed to in writing, shall any Contributor be
      liable to You for damages, including any direct, indirect, special,
      incidental, or consequential damages of any character arising as a
      result of this License or out of the use or inability to use the
      Work (including but not limited to damages for loss of goodwill,
      work stoppage, computer failure or malfunction, or any and all
      other commercial damages or losses), even if such Contributor
      has been advised of the possibility of such damages.

   9. Accepting Warranty or Additional Liability. While redistributing
      the Work or Derivative Works thereof, You may choose to offer,
      and charge a fee for, acceptance of support, warranty, indemnity,
      or other liability obligations and/or rights consistent with this
      License. However, in accepting such obligations, You may act only
      on Your own behalf and on Your sole responsibility, not on behalf
      of any other Contributor, and only if You agree to indemnify,
      defend, and hold each Contributor harmless for any liability
      incurred by, or claims asserted against, such Contributor by reason
      of your accepting any such warranty or additional liability.

   END OF TERMS AND CONDITIONS
```

---

### ISC License

The following packages are licensed under the ISC License:

**Frontend:** lucide-react

```
ISC License

Copyright (c) [year] [copyright holders]

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
PERFORMANCE OF THIS SOFTWARE.
```

---

## Special Acknowledgments

### React (MIT)
Copyright (c) Meta Platforms, Inc. and affiliates.

### TypeScript (Apache-2.0)
Copyright (c) Microsoft Corporation. All rights reserved.

### FastAPI (MIT)
Copyright (c) 2018-present Sebastián Ramírez

### Plotly.js (MIT)
Copyright (c) 2025 Plotly, Inc.

### AG Grid Community (MIT)
Copyright (c) AG Grid Ltd.

### SQLAlchemy (MIT)
Copyright (c) 2005-2025 Michael Bayer and contributors.

### TanStack Query (MIT)
Copyright (c) 2021-present Tanner Linsley

### Lucide (ISC)
Copyright (c) 2025 Lucide Contributors
Portions copyright (c) Cole Bemis 2013-2023 (from Feather Icons, MIT License)

### Pydantic (MIT)
Copyright (c) 2017-present Pydantic Services Inc. and individual contributors.

---

## Notes

1. **AG Grid**: This project uses `ag-grid-community` which is MIT licensed. The enterprise
   version (`ag-grid-enterprise`) requires a commercial license and is NOT used in this project.

2. **Redis Client vs Server**: The `redis` Python package (redis-py) is MIT licensed. Note that
   Redis server 7.4+ uses a dual RSALv2/SSPLv1 license. This license document covers only the
   Python client library, not the Redis server.

3. **python-dateutil**: This package is dual-licensed under Apache-2.0 and BSD-3-Clause.
   Code contributed before December 1, 2017 is BSD-3-Clause only.

4. **Lucide Icons**: Lucide is a fork of Feather Icons. The Lucide portions are ISC licensed,
   while the original Feather Icons portions remain MIT licensed.

---

## Conclusion

All dependencies in this project use permissive open-source licenses (MIT, BSD-3-Clause,
Apache-2.0, ISC). There are:

- **No copyleft licenses** (GPL, LGPL, AGPL) that would require derivative works to be
  open-sourced
- **No license incompatibilities** between dependencies
- **No restrictions** on commercial use or proprietary distribution

This project is **safe for public release** from a licensing perspective, provided this
THIRD_PARTY_LICENSES.md file is included with distributions.
