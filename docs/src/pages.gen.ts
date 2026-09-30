// deno-fmt-ignore-file
// biome-ignore format: generated types do not need formatting
// prettier-ignore
import type { PathsForPages } from 'waku/router'

// prettier-ignore
type Page =
  | { path: '/'; render: 'static' }
  | { path: '/src/DeployManager/contract.DeployManager'; render: 'static' }
  | { path: '/src/DeployManager/interface.IDeployManager'; render: 'static' }
  | { path: '/src/ERC1155Airdroper/contract.ERC1155Airdroper'; render: 'static' }
  | { path: '/src/ERC20Airdroper/contract.ERC20Airdroper'; render: 'static' }
  | { path: '/src/ERC721Airdroper/contract.ERC721Airdroper'; render: 'static' }
  | { path: '/src/LiniarVesting/contract.Vesting'; render: 'static' }
  | { path: '/src/LiniarVesting/interface.IVesting'; render: 'static' }
  | { path: '/src/LiniarVesting/library.VestingLib'; render: 'static' }
  | { path: '/src/UtilityContract/abstract.AbstractUtilityContract'; render: 'static' }
  | { path: '/src/UtilityContract/interface.IUtilityContract'; render: 'static' }
  | { path: '/src/contract.ERC20Mock'; render: 'static' }

// prettier-ignore
declare module 'waku/router' {
  interface RouteConfig {
    paths: PathsForPages<Page>
  }
  interface CreatePagesConfig {
    pages: Page
  }
}
